//
//  AppDelegate.m
//  IcnsOptim
//
//  Created by Sveinbjorn Thordarson on 24.5.2025.
//

#import "AppDelegate.h"

#import "IcnsOptimizer.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    IcnsOptimizer *opt = [[IcnsOptimizer alloc] initWithIcnsPath:@"/Users/sveinbjorn/diskimage.icns"];
    [opt optimizeIcon];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
