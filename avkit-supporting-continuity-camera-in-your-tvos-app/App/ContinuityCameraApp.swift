/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's central type that creates the main view and helper type instances.
*/

import SwiftUI

/// The app's main entry point that creates its content view and helper type instances.
@main
struct ContinuityCaptureApp: App {

    /// A capture session manager that connects the app to another device's camera.
    ///
    /// The manager responds to the app's camera-centric UI and configuration.
    var captureManager = CaptureManager()

    /// An audio session manager that connects the app to another device's microphone.
    ///
    /// The manager responds to the app's audio-centric UI and configures the
    /// system's audio engine.
    var audioCapturer = AudioCapturer()

    /// Saves still images from a camera to the device's photo library.
    var photoCapturer = PhotoCapturer()

    /// Saves video recordings from a camera to the device's photo library.
    var videoCapturer = VideoCapturer()

    init() {
        // Connects the photo and video capturers to the capture manager.
        captureManager.addOutput(photoCapturer.photoOutput)
        captureManager.addOutput(videoCapturer.movieFileOutput)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(captureManager: captureManager,
                        photoCapturer: photoCapturer,
                        videoCapturer: videoCapturer,
                        audioCapturer: audioCapturer)
        }
    }
}
