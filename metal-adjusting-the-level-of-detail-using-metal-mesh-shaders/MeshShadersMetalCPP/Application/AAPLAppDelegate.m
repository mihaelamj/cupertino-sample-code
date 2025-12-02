/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cross-platform app delegate.
*/

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

/// Tells the operating system that the app needs to terminate when the window closes.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(PlatformApplication *)sender
{
    return YES;
}

@end
