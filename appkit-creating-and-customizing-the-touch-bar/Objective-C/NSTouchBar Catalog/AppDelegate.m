/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
NSApplicationDelegate that responds to NSApplication events.
*/

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application.
    
    /** You can get the Customize menu item to display on the View menu by:
        1: Setting the “automaticCustomizeTouchBarMenuItemEnabled” property to YES
        or
        2: Create your own menu item and connect it to the "toggleTouchBarCustomizationPalette:" selector.
    */
    // Opt in to allow customization of the touch bar.
    if ([[NSApplication sharedApplication] respondsToSelector:@selector(isAutomaticCustomizeTouchBarMenuItemEnabled)])
    {
        [NSApplication sharedApplication].automaticCustomizeTouchBarMenuItemEnabled = YES;
    }
}

@end
