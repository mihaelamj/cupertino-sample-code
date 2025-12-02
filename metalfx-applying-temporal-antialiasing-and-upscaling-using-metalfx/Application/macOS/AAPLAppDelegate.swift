/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file provides the app delegate for the MetalFX sample.
*/

import Cocoa

@main
class AAPLAppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
