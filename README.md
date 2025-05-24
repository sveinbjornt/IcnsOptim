[![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white)]()
[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Language](https://img.shields.io/badge/language-objective--c-lightgrey)](https://en.wikipedia.org/wiki/Objective-C)
[![Release](https://shields.io/github/v/release/sveinbjornt/icnsoptim?display_name=tag)](https://github.com/sveinbjornt/IcnsOptim/releases)
[![Build](https://github.com/sveinbjornt/icnsoptim/actions/workflows/macos.yml/badge.svg)](https://github.com/sveinbjornt/IcnsOptim/actions)

# IcnsOptim

IcnsOptim is a macOS utility to ***losslessly*** optimize Apple Icon (`.icns`) files.
This is accomplished by disassembling the file, brute-force optimizing
the contained PNG images with [`oxipng`](https://github.com/shssoichiro/oxipng) and
rebuilding the icon using [`createicns`](https://github.com/avl7771/createicns),
a utility which doesn't bloat and tamper with the provided PNG files,
unlike Apple's annoying [`iconutil`](https://www.unix.com/man_page/osx/1/iconutil).

Lossless compression results vary but are usually significant, typically around 20-50%. 
An experiment where optimization was performed on all icon files in the `/Applications`
directory hierarchy resulted in an average ~30% reduction in size.

## App

WIP

## Command line tool

The repository contains the bash script `imgoptim.sh`, which can 
optimize icons via the command line. Use it thus:

```bash
bash icnsoptim.sh path/to/file.icns
```

The script expects `oxipng` and `createicns` binaries to be present in the same
directory as the script.

## BSD License 

Copyright (C) 2025 Sveinbjorn Thordarson 
&lt;<a href="mailto:sveinbjorn@sveinbjorn.org">sveinbjorn@sveinbjorn.org</a>&gt;

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or other
materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may
be used to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.


