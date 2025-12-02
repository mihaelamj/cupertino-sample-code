/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol that represents the model for the camera view.
*/

import SwiftUI
import Combine
import CoreMedia
import AVFoundation

/// A protocol that represents the model for the camera view.
///
/// The AVFoundation camera APIs require running on a physical device. The app defines the model as a protocol to make it
/// simple to swap out the real camera for a test camera when previewing SwiftUI views.
@MainActor
protocol Camera: AnyObject, SendableMetatype {
    
    /// Provides the current status of the camera.
    var status: CameraStatus { get }
    
    var metadataManager: CinematicMetadataManager { get }

    /// The camera's current activity state, which can be movie capture, or idle.
    var captureActivity: CaptureActivity { get }

    /// The source of video content for a camera preview.
    var preview: CALayer { get }
    
    /// Starts the camera capture pipeline.
    func start() async

    /// Switches between video devices available on the host system.
    func switchVideoDevices() async
    
    /// A Boolean value that indicates whether the camera is currently switching video devices.
    var isSwitchingVideoDevices: Bool { get }
    
    /// Starts or stops recording a movie, and writes it to the person's photos library when complete.
    func toggleRecording() async
    
    /// A thumbnail image for the most recent video capture.
    var thumbnail: CGImage? { get }
    
    /// An error if the camera encountered a problem.
    var error: Error? { get }
    
    /// Simulated aperture values.
    var simulatedAperture: Float { get set }
    var maxSimulatedAperture: Float { get }
    var minSimulatedAperture: Float { get }
            
    func tapPreview(at point: CGPoint) async
    
    func longPressPreview(at point: CGPoint) async
}

struct CinematicFocusMetadata {
	
    let focusMode: AVCaptureDevice.CinematicVideoFocusMode
    let layerBoundsNormalized: CGRect
    let objectID: NSInteger
    let isFixedFocus: Bool
    let objectType: AVMetadataObject.ObjectType
	
	init(metadataObject: AVMetadataObject, layerBoundsNormalized: CGRect) {
        
        self.layerBoundsNormalized = layerBoundsNormalized
		focusMode = metadataObject.cinematicVideoFocusMode
		isFixedFocus = metadataObject.isFixedFocus
        objectType = metadataObject.type
        objectID = metadataObject.objectID
	}
}
