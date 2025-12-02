/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate for the application.
*/

#import "AAPLAppDelegate.h"

@interface AAPLAppDelegate ()
@end

@implementation AAPLAppDelegate
{
}

/// Callback when the app launches.
- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
}

/// Callback when the app needs to close.
- (void)applicationWillTerminate:(NSNotification*)aNotification
{
}

/// Says that the application closes if all the windows are closed.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender
{
    return YES;
}

@end
