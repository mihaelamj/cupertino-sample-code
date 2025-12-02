/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the camera.
*/

import SwiftUI
import Combine
import CoreMedia
import AVFoundation

/// An object that provides the interface to the features of the camera.
///
/// This object provides the default implementation of the `Camera` protocol, which defines the interface
/// to configure the camera hardware and capture media. `CameraModel` doesn't perform capture itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `CaptureService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewCameraModel` instead.
///
@MainActor
@Observable
final class CameraModel: Camera {
    
    /// A preview layer that presents the captured video frames.
    let preview: CALayer = AVSampleBufferDisplayLayer()
    
    var metadataManager: CinematicMetadataManager {
        return captureService.metadataManager
    }
        
    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown
    
    /// The current state of movie capture.
    private(set) var captureActivity = CaptureActivity.idle
    
    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false
    
    /// A thumbnail for the last captured video.
    private(set) var thumbnail: CGImage?
    
    /// An error that indicates the details of an error during movie capture.
    private(set) var error: Error?
    
    /// Simulated aperture values.
    var simulatedAperture: Float = 4.5 {
        didSet {
            Task {
                await captureService.setSimulatedAperture(simulatedAperture)
            }
        }
    }
    private(set) var minSimulatedAperture: Float = 2.0
    private(set) var maxSimulatedAperture: Float = 16.0

    /// An object that saves captured media to a person's photos library.
    private let mediaLibrary = MediaLibrary()
    
    /// An object that manages the app's capture functionality.
    private let captureService: CaptureService
    
    init() {
        captureService = CaptureService(previewLayer: preview as! AVSampleBufferDisplayLayer)
    }
    
    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    func start() async {
        // Verify that the person authorizes the app to use device cameras and microphones.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start()
            minSimulatedAperture = await captureService.minSimulatedAperture
            maxSimulatedAperture = await captureService.maxSimulatedAperture
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    // MARK: - Changing capture devices

    /// Selects the next available video device for capture.
    func switchVideoDevices() async {
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
    }
    
    /// Toggles the state of recording.
    func toggleRecording() async {
        switch await captureService.captureActivity {
        case .movieCapture:
            do {
                // If currently recording, stop the recording and write the movie to the library.
                let movie = try await captureService.stopRecording()
                try await mediaLibrary.save(movie: movie)
            } catch {
                self.error = error
            }
        default:
            // In any other case, start recording.
            await captureService.startRecording()
        }
    }
    
    // MARK: - Internal state observations
    
    // Set up camera's state observations.
    private func observeState() {
        Task {
            // Await new thumbnails that the media library generates when saving a file.
            for await thumbnail in mediaLibrary.thumbnails.compactMap({ $0 }) {
                self.thumbnail = thumbnail
            }
        }
        
        Task {
            // Await new capture activity values from the capture service.
            for await activity in await captureService.$captureActivity.values {
                captureActivity = activity
            }
        }
    }
    
    func tapPreview(at point: CGPoint) async {
        await captureService.tapPreview(at: point)
    }
    
    func longPressPreview(at point: CGPoint) async {
        await captureService.longPressPreview(at: point)
    }
    
}
