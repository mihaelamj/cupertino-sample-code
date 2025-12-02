/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the camera.
*/

import SwiftUI
import Combine

/// An object that provides the interface to the features of the camera.
///
/// This object provides the default implementation of the `Camera` protocol, which defines the interface
/// to configure the camera hardware and to capture media. `CameraModel` doesn't perform capture itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `CaptureService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewCameraModel` instead.
///
@Observable
final class CameraModel: Camera {
    
    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown
    
    /// The current state of photo or movie capture.
    private(set) var captureActivity = CaptureActivity.idle
    
    /// The current camera orientation.
    private(set) var cameraOrientation: CameraOrientation = .unknown
    
    /// The current camera-zoom magnification factor.
    private(set) var zoomFactor: Double = 1.0
    
    /// The current state of the recording UI.
    var isRecording: Bool = false
    
    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false
    
    /// An error that indicates the details of an error during photo or movie capture.
    private(set) var error: Error?
    
    /// An object that provides the connection between the capture session and the video preview layer.
    var previewSource: PreviewSource { captureService.previewSource }
    
    /// An object that saves captured media to a person's Photos library.
    private let mediaLibrary = MediaLibrary()
    
    /// An object that manages the app's capture functionality.
    private let captureService = CaptureService()
    
    init() {
        //
    }
    
    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    func start() async {
        // Verify that the person authorizes the app to use the device's cameras.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start()
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    // MARK: - Changing modes and devices
    
    /// Selects the next available video device for capture.
    func switchVideoDevices() async {
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
    }
    
    // MARK: - Video capture
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
    
    // MARK: - Zoom
    /// Zooms in or out of the video feed.
    func updateMagnification(for zoomType: CameraZoomType, by scale: Double) async {
        await captureService.updateMagnification(for: zoomType, by: scale)
    }
    
    // MARK: - Internal state observations
    /// Set up the camera's state observations.
    private func observeState() {
        Task {
            // Await new capture-activity values from the capture service.
            for await activity in await captureService.$captureActivity.values {
                // Forward the activity to the UI.
                captureActivity = activity
            }
        }
        
        Task {
            // Await orientation changes.
            for await cameraOrientationUpdate in await captureService.$cameraOrientation.values {
                cameraOrientation = cameraOrientationUpdate
            }
        }
        
        Task {
            for await zoomFactorUpdate in await captureService.$zoomFactor.values {
                zoomFactor = zoomFactorUpdate
            }
        }
    }
    
    // MARK: - DockKit tracking delegate
    /// Set the tracking delegate.
    func setTrackingServiceDelegate(_ service: DockAccessoryTrackingDelegate) async {
        await captureService.setTrackingServiceDelegate(service)
    }
    
    // MARK: - Miscellaneous
    /// Convert a point from the view-space coordinates to the device coordinates, where (0,0) is top left and (1,1) is bottom right.
    func devicePointConverted(from point: CGPoint) async -> CGPoint {
        return await captureService.devicePointConverted(from: point)
    }
    
    func layerRectConverted(from rect: CGRect) async -> CGRect {
        return await captureService.layerRectConverted(from: rect)
    }
}

extension CameraModel: CameraCaptureDelegate {
    func startOrStartCapture() {
        Task {
            isRecording.toggle()
            await toggleRecording()
        }
    }
    
    func switchCamera() {
        Task {
            await switchVideoDevices()
        }
    }
    
    func zoom(type: CameraZoomType, factor: Double) {
        Task {
            await updateMagnification(for: type, by: factor)
        }
    }
    
    func convertToViewSpace(from rect: CGRect) async -> CGRect {
        return await layerRectConverted(from: rect)
    }
}
