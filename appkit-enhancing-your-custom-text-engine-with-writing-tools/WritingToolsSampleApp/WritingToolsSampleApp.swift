/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate.
*/

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        windowController = storyboard.instantiateController(withIdentifier: "MainWindowController") as? NSWindowController
        windowController?.showWindow(self)
        windowController?.window?.makeKeyAndOrderFront(self)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}
