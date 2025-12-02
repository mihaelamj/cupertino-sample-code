/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate class.
*/

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminate(_ sender: NSApplication)-> NSApplication.TerminateReply {
        return .terminateNow
    }

}
