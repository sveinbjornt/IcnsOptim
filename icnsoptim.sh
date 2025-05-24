#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -o pipefail

# --- Configuration ---
# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CREATEICNS_TOOL="${SCRIPT_DIR}/createicns"
OXIPNG_TOOL="${SCRIPT_DIR}/oxipng"
ICONUTIL_TOOL="/usr/bin/iconutil"

# --- Helper Functions ---
usage() {
    echo "Usage: $0 <input.icns> [output_path/output.icns]"
    echo "  <input.icns>: Path to the .icns file to optimize."
    echo "  [output_path/output.icns]: Optional. Full path for the optimized .icns file."
    echo "                             If not provided, output will be <input_basename>-optimized.icns"
    echo "                             in the current working directory."
    exit 1
}

cleanup() {
    if [ -n "${ICONSET_DIR:-}" ] && [ -d "${ICONSET_DIR}" ]; then
        echo "Cleaning up temporary iconset directory: ${ICONSET_DIR}"
        rm -rf "${ICONSET_DIR}"
    fi
}

# --- Argument Parsing & Validation ---
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

INPUT_ICNS_FILE="$1"
OUTPUT_ICNS_ARGUMENT="${2:-}" # Empty if not provided

if [ ! -f "${INPUT_ICNS_FILE}" ]; then
    echo "Error: Input ICNS file not found: ${INPUT_ICNS_FILE}"
    exit 1
fi

if [[ "${INPUT_ICNS_FILE##*.}" != "icns" ]]; then
    echo "Warning: Input file '${INPUT_ICNS_FILE}' does not have an .icns extension."
    # Allow proceeding, iconutil will fail if it's not a valid icns
fi

if [ ! -x "${CREATEICNS_TOOL}" ]; then
    echo "Error: createicns tool not found or not executable at ${CREATEICNS_TOOL}"
    exit 1
fi

if [ ! -x "${OXIPNG_TOOL}" ]; then
    echo "Error: oxipng tool not found or not executable at ${OXIPNG_TOOL}"
    exit 1
fi

if [ ! -x "${ICONUTIL_TOOL}" ]; then
    echo "Error: iconutil tool not found or not executable at ${ICONUTIL_TOOL}"
    echo "This script is intended for macOS."
    exit 1
fi

if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' command is not installed, but is required for percentage calculations."
    exit 1
fi

# --- Determine Filenames and Paths ---
# Get the absolute path of the input file
ABS_INPUT_ICNS_FILE="$(cd "$(dirname "${INPUT_ICNS_FILE}")" && pwd)/$(basename "${INPUT_ICNS_FILE}")"

# Basename of the input file (e.g., "MyApp" from "MyApp.icns")
INPUT_BASENAME=$(basename "${ABS_INPUT_ICNS_FILE}" .icns)

# Name of the iconset directory (will be created in CWD)
ICONSET_DIR="${PWD}/${INPUT_BASENAME}.iconset" # PWD ensures it's in the current dir

# Determine output file path
if [ -n "${OUTPUT_ICNS_ARGUMENT}" ]; then
    OUTPUT_ICNS_FILE="${OUTPUT_ICNS_ARGUMENT}"
else
    OUTPUT_ICNS_FILE="${PWD}/${INPUT_BASENAME}-optimized.icns"
fi

# Ensure output directory exists if a full path was given for output
OUTPUT_DIR=$(dirname "${OUTPUT_ICNS_FILE}")
if [ ! -d "${OUTPUT_DIR}" ]; then
    echo "Creating output directory: ${OUTPUT_DIR}"
    mkdir -p "${OUTPUT_DIR}"
fi

# --- Get Original File Size ---
ORIGINAL_ICNS_SIZE=$(stat -f %z "${ABS_INPUT_ICNS_FILE}")
if ! [[ "${ORIGINAL_ICNS_SIZE}" =~ ^[0-9]+$ ]]; then # Check if it's a non-negative integer
    echo "Error: Could not determine a valid size for input file ${ABS_INPUT_ICNS_FILE}."
    echo "Reported size: '${ORIGINAL_ICNS_SIZE}'"
    exit 1
fi

# --- Main Script Logic ---

# Setup trap for cleanup
trap cleanup EXIT ERR INT TERM

echo "Optimizing ICNS file: ${ABS_INPUT_ICNS_FILE}"
echo "Temporary iconset will be: ${ICONSET_DIR}"
echo "Optimized ICNS will be saved to: ${OUTPUT_ICNS_FILE}"
echo "---"

# 1. Run iconutil to create iconset
echo "1. Extracting ICNS to iconset..."
if [ -d "${ICONSET_DIR}" ]; then
    echo "Warning: Iconset directory ${ICONSET_DIR} already exists. Removing it."
    rm -rf "${ICONSET_DIR}"
fi
"${ICONUTIL_TOOL}" -c iconset "${ABS_INPUT_ICNS_FILE}" -o "${ICONSET_DIR}"
# Explicitly providing -o for iconutil ensures it goes where ICONSET_DIR expects.

if [ ! -d "${ICONSET_DIR}" ]; then
    echo "Error: Failed to create iconset directory ${ICONSET_DIR} using iconutil."
    exit 1
fi
echo "Iconset created at: ${ICONSET_DIR}"
echo "---"

# 2. Run oxipng on all PNG images in the iconset directory
echo "2. Optimizing PNG images in ${ICONSET_DIR}..."
png_files_found=0
# Use find for robustness, especially if there could be symlinks or unusual filenames.
# `-maxdepth 1` ensures we only look in the top level of the iconset dir.
find "${ICONSET_DIR}" -maxdepth 1 -type f -name "*.png" -print0 | while IFS= read -r -d $'\0' png_file; do
    echo "   Optimizing ${png_file}..."
    "${OXIPNG_TOOL}" --strip safe -o max "${png_file}"
    png_files_found=1
done

if [ "$png_files_found" -eq 0 ]; then
    echo "Warning: No PNG files found in ${ICONSET_DIR} to optimize."
else
    echo "PNG optimization complete."
fi
echo "---"

# 3. Run createicns on the iconset
echo "3. Creating new optimized ICNS file..."
"${CREATEICNS_TOOL}" "${ICONSET_DIR}" "${OUTPUT_ICNS_FILE}"
echo "Optimized ICNS file created: ${OUTPUT_ICNS_FILE}"
echo "---"

# --- Report Sizes and Savings ---
echo "File Size Analysis:"

if [ -f "${OUTPUT_ICNS_FILE}" ]; then
    OPTIMIZED_ICNS_SIZE=$(stat -f %z "${OUTPUT_ICNS_FILE}")
    if ! [[ "${OPTIMIZED_ICNS_SIZE}" =~ ^[0-9]+$ ]]; then
        echo "Error: Could not determine a valid size for optimized file ${OUTPUT_ICNS_FILE}."
        echo "Reported size: '${OPTIMIZED_ICNS_SIZE}'"
        # Continue to print original, but skip comparison
        OPTIMIZED_ICNS_SIZE=-1 # Indicate error for logic below
    fi

    # Using printf for aligned output and locale-specific thousand separators (e.g., commas)
    printf "Original ICNS size:    %15s bytes\n" "$(printf "%d" "${ORIGINAL_ICNS_SIZE}")"
    if [ "${OPTIMIZED_ICNS_SIZE}" -ge 0 ]; then
        printf "Optimized ICNS size:   %15s bytes\n" "$(printf "%d" "${OPTIMIZED_ICNS_SIZE}")"

        if [ "${ORIGINAL_ICNS_SIZE}" -gt 0 ]; then
            SAVED_BYTES=$((ORIGINAL_ICNS_SIZE - OPTIMIZED_ICNS_SIZE))

            if [ "${SAVED_BYTES}" -gt 0 ]; then
                PERCENTAGE_SAVED=$(echo "scale=2; (${SAVED_BYTES} * 100) / ${ORIGINAL_ICNS_SIZE}" | bc)
                printf "Bytes saved:           %15s bytes\n" "$(printf "%d" "${SAVED_BYTES}")"
                printf "Percentage saved:      %15s %%\n" "${PERCENTAGE_SAVED}"
            elif [ "${SAVED_BYTES}" -lt 0 ]; then
                INCREASED_BYTES=$((OPTIMIZED_ICNS_SIZE - ORIGINAL_ICNS_SIZE)) # Positive value
                PERCENTAGE_INCREASE=$(echo "scale=2; (${INCREASED_BYTES} * 100) / ${ORIGINAL_ICNS_SIZE}" | bc)
                printf "File size increased by:%15s bytes\n" "$(printf "%d" "${INCREASED_BYTES}")"
                printf "Percentage increase:   %15s %% (Optimized is larger)\n" "${PERCENTAGE_INCREASE}"
            else # SAVED_BYTES is 0
                printf "Bytes saved:           %15s bytes\n" "0"
                printf "Percentage saved:      %15s %%\n" "0.00"
            fi
        elif [ "${ORIGINAL_ICNS_SIZE}" -eq 0 ]; then # Original size was 0
            if [ "${OPTIMIZED_ICNS_SIZE}" -gt 0 ]; then
                echo "Original file was 0 bytes. Optimized file is $(printf "%d" "${OPTIMIZED_ICNS_SIZE}") bytes."
            else # Both are 0 bytes
                echo "No change in file size (both 0 bytes)."
            fi
        fi
    else
         echo "Could not report optimized size details due to previous error."
    fi
else
    printf "Original ICNS size:    %15s bytes\n" "$(printf "%d" "${ORIGINAL_ICNS_SIZE}")"
    echo "Error: Optimized ICNS file ${OUTPUT_ICNS_FILE} was not found. Cannot report optimized size."
fi
echo "---"

echo "Optimization process complete!"

exit 0
