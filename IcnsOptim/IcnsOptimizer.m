//
//  IcnsOptimizer.m
//  IcnsOptim
//
//  Created by Sveinbjorn Thordarson on 24.5.2025.
//

#import "IcnsOptimizer.h"

NS_ASSUME_NONNULL_BEGIN

@interface IcnsOptimizer()

@property (strong, retain) NSString *originalIcnsPath;
@property (strong, retain) NSString *uuid;
@property (strong, retain) NSString *workDir;
@property (strong, retain) NSString *icnsPath;
@property (strong, retain) NSString *iconsetPath;
@property (strong, retain) NSString *optimizedIcnsPath;

@end


@implementation IcnsOptimizer

- (instancetype)initWithIcnsPath:(NSString *)path {
    
    self = [super init];
    if (self) {
        self.originalIcnsPath = path;
    }
    return self;
}

- (void)optimizeIcon {
    
    self.uuid = [[NSUUID UUID] UUIDString];

    NSString *icnsFilename = [self.originalIcnsPath lastPathComponent];
    NSString *icnsBasename = [icnsFilename stringByDeletingPathExtension];
    NSString *dirName = [NSString stringWithFormat:@"%@-%@", icnsBasename, self.uuid];
    self.workDir = [NSTemporaryDirectory() stringByAppendingPathComponent:dirName];
    NSLog(self.workDir);
    
    // Create work directory
    NSError *error;
    BOOL success = [FILEMGR createDirectoryAtURL:[NSURL fileURLWithPath:self.workDir]
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:&error];
    if (!success) {
        NSLog(@"%@", [error description]);
        return;
    }
    
    self.icnsPath = [self.workDir stringByAppendingPathComponent:icnsFilename];
    success = [FILEMGR copyItemAtPath:self.originalIcnsPath toPath:self.icnsPath error:&error];
    if (!success) {
        NSLog(@"%@", [error description]);
        return;
    }
    
    self.iconsetPath = [[self.icnsPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"iconset"];
    
    // icontool -c iconset icnsPath -o iconsetPath
    [self runTool:ICONUTIL_PATH
         withArgs:@[@"-c", @"iconset", self.icnsPath, @"-o", self.iconsetPath]
              cwd:self.workDir];
    
    
    NSArray *iconsetFiles = [FILEMGR contentsOfDirectoryAtPath:self.iconsetPath
                                                         error:nil];

    
    // oxipng -o max --strip safe --alpha file.png

//    NSMutableArray *pngFiles = [NSMutableArray array];
    for (NSString *pngFile in iconsetFiles) {
        NSString *path = [self.iconsetPath stringByAppendingPathComponent:pngFile];
//        [pngFiles addObject:path];
        [self runTool:OXIPNG_PATH
             withArgs:@[@"-o", @"max", @"--strip", @"safe", @"--alpha", @"-Z", path]
                  cwd:self.workDir];
    }
    
    NSString *optIconsetPath = [[NSString stringWithFormat:@"%@-optimized", [self.icnsPath stringByDeletingPathExtension]] stringByAppendingPathExtension:@"iconset"];
    [FILEMGR moveItemAtPath:self.iconsetPath toPath:optIconsetPath error:&error];
    
    // createicns iconsetPath
    [self runTool:CREATEICNS_PATH
         withArgs:@[optIconsetPath]
              cwd:self.workDir];
    
    NSLog(@"All done!");
}

- (void)runTool:(NSString *)toolPath withArgs:(NSArray *)args cwd:(NSString *)cwDir {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:toolPath];
    [task setArguments:args];
    [task setCurrentDirectoryPath:cwDir];
    [task launch];
    [task waitUntilExit];
}

@end

NS_ASSUME_NONNULL_END
