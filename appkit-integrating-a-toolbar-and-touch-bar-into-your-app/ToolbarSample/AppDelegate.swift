/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main NSApplicationDelegate to this sample.
*/

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /// - Tag: CustomizeTouchBar
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Allow users to customize the app's Touch Bar items.
        NSApplication.shared.isAutomaticCustomizeTouchBarMenuItemEnabled = true
        
    }

}
