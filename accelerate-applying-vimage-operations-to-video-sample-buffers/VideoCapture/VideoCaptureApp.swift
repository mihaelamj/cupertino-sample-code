/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The YUV-to-RGB application file.
*/
import SwiftUI

@main
struct VideoCaptureApp: App {
    
    @StateObject private var videoCapture = VideoCapture()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(videoCapture)
                .onAppear {
                    appDelegate.videoCapture = videoCapture
                }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var videoCapture: VideoCapture?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        videoCapture?.stopRunning()
    }
}
