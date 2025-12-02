/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App Delegate for ImageSaliency-macOS used here to override the funciton applicationShouldTerminateAfterLastWindowClosed to always be true
*/

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}

