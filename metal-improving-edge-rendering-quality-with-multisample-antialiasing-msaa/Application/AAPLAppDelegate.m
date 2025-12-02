/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cross-platform app delegate.
*/

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

#if TARGET_MACOS

/// Tells the operating system that the app needs to terminate when the window closes.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)app
{
    return YES;
}

#endif

@end
