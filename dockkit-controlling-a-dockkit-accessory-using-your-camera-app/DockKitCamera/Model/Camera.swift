/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol that represents the model for the camera view.
*/

import SwiftUI

/// A protocol that represents the model for the camera view.
///
/// The AVFoundation camera APIs require a physical device to run. The app defines the model as a protocol to make it
/// simple to swap out the real camera for a test camera when previewing SwiftUI views.
@MainActor
protocol Camera: AnyObject {
    
    /// Provides the current status of the camera.
    var status: CameraStatus { get }

    /// The camera's current activity state, which can be photo capture, movie capture, or idle.
    var captureActivity: CaptureActivity { get }
    
    /// The camera's current orientation.
    var cameraOrientation: CameraOrientation { get }
    
    /// The camera's current zoom magnification factor.
    var zoomFactor: Double { get }
    
    /// The current state of the recording UI.
    var isRecording: Bool { get set }

    /// The source of the video content for a camera preview.
    var previewSource: PreviewSource { get }
    
    /// Starts the camera-capture pipeline.
    func start() async

    /// Switches between video devices available on the host system.
    func switchVideoDevices() async
    
    /// A Boolean value that indicates whether the camera is currently switching video devices.
    var isSwitchingVideoDevices: Bool { get }
    
    /// Starts or stops recording a movie, and writes it to the device's Photos library when complete.
    func toggleRecording() async
    
    /// An error if the camera encounters a problem.
    var error: Error? { get }
    
    /// Set the tracking delegate.
    func setTrackingServiceDelegate(_ service: DockAccessoryTrackingDelegate) async
    
    /// Convert a point from the view-space coordinates to the device coordinates, where (0,0) is top left and (1,1) is bottom right.
    func devicePointConverted(from point: CGPoint) async -> CGPoint
}
