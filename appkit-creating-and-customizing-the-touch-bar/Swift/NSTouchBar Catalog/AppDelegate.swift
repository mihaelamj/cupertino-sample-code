/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
NSApplicationDelegate that responds to NSApplication events.
*/

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Insert code here to initialize your application.
        
        // You can get the “Customize Touch Bar” menu item to display on the View menu by:
        // 1: Setting the “automaticCustomizeTouchBarMenuItemEnabled” property to YES
        // or
        // 2: Create your own menu item and connect it to the "toggleTouchBarCustomizationPalette:" selector.
        
        // Opt in for allowing customization of the NSTouchBar instance throughout the app.
        //
        NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
    }
}
