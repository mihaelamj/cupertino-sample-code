/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the iOS app delegate.
*/
#import "AAPLAppDelegate.h"

@interface AAPLAppDelegate ()
@end

@implementation AAPLAppDelegate

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
    // Insert code here to initialize your app.
}

- (void) applicationWillTerminate:(NSNotification*) aNotification
{
    // Insert code here to tear down your app.
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication*) sender
{
    return YES;
}

@end
