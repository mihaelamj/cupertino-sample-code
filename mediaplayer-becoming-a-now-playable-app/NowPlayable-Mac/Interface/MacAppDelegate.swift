/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate that manages the application life cycle.
*/

import Cocoa

@NSApplicationMain
class MacAppDelegate: NSObject, NSApplicationDelegate {
    
    // A direct reference to this app delegate.
    
    static private(set) var shared: MacAppDelegate!
    
    // Initial setup when the app has finished launching.
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        MacAppDelegate.shared = self
        
        // Create the data model.
        
        ConfigModel.shared = ConfigModel(nowPlayableBehavior: MacNowPlayableBehavior())
        
        // Notify the UI that the model has been changed.
        
        MacWindowController.shared.updateConfig()
    }
    
}

