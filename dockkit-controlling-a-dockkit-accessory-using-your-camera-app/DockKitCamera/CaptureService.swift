/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages a capture session and its inputs and outputs.
*/

import Foundation
import AVFoundation
import Combine
import UIKit

/// An actor that manages the capture pipeline, which includes the capture session, device inputs, and capture outputs.
/// The app defines it as an `actor` type to ensure that all camera operations happen off the `@MainActor`.
actor CaptureService {
    
    /// A value that indicates whether the capture service is idle or capturing a photo or movie.
    @Published private(set) var captureActivity: CaptureActivity = .idle
    
    @Published private(set) var metadataObjects: [AVMetadataObject] = []
    
    @Published private(set) var cameraOrientation: CameraOrientation = .unknown
    
    @Published private(set) var zoomFactor = 1.0
    
    private var maxZoomFactor = 5.0
    private var minZoomFactor = 1.0
    
    /// A type that connects a preview destination with the capture session.
    nonisolated let previewSource: PreviewSource
    
    // The app's capture session.
    private let captureSession = AVCaptureSession()
    
    // An object that manages the app's video-capture behavior.
    private let movieCapture = MovieCapture()
    
    // An internal collection of output services.
    private var outputServices: [any OutputService] { [movieCapture] }
    
    // The video input for the currently selected device camera.
    private var activeVideoInput: AVCaptureDeviceInput?
    
    // An object the service uses to retrieve capture devices.
    private let deviceLookup = DeviceLookup()
    
    // An object that monitors video-device rotations.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var rotationObservers = [AnyObject]()
    
    // A Boolean value that indicates whether the actor finished its required configuration.
    private var isSetUp = false
    
    // A delegate to perform tracking.
    private(set) weak var trackingDelegate: DockAccessoryTrackingDelegate?
    
    init() {
        // Create a source object to connect the preview view with the capture session.
        previewSource = DefaultPreviewSource(session: captureSession)
    }
    
    // MARK: - Authorization
    /// A Boolean value that indicates whether a person authorizes the app to use
    /// the device's cameras. If they didn't previously authorize the
    /// app, querying this property prompts them for authorization.
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            // Determine whether a person previously authorized camera access.
            var isAuthorized = status == .authorized
            // If the system can't determine the authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }
    
    // MARK: - Capture session life cycle
    func start() async throws {
        // Exit early if there's no authorization or if the session is already running.
        guard await isAuthorized, !captureSession.isRunning else { return }
        // Configure the session and start it.
        try setUpSession()
        captureSession.startRunning()
    }
    
    // MARK: - Capture setup
    // Performs the initial capture-session configuration.
    private func setUpSession() throws {
        // Return early if already set up.
        guard !isSetUp else { return }
        
        // Assign the capture activity.
        movieCapture.$captureActivity.assign(to: &$captureActivity)
        
        Task {
            // Listen for the metadata objects update.
            for await metadataObjectsUpdate in movieCapture.$metadataObjects.values {
                trackingDelegate?.track(metadata: metadataObjectsUpdate,
                                        sampleBuffer: movieCapture.sampleBuffer,
                                        deviceType: currentDevice.deviceType,
                                        devicePosition: currentDevice.position)
            }
        }
        
        do {
            // Retrieve the default camera.
            let defaultCamera = try deviceLookup.defaultCamera

            // Add inputs for the default camera.
            activeVideoInput = try addInput(for: defaultCamera)
            
            // Configure the session for movie capture.
            captureSession.sessionPreset = .high
            
            try addOutput(movieCapture.videoOutput)
            try addOutput(movieCapture.metadataOutput)
            let objectTypes: [AVMetadataObject.ObjectType] = [.face, .humanBody]
            movieCapture.metadataOutput.metadataObjectTypes = objectTypes
            try addOutput(movieCapture.movieOutput)
                        
            // Configure a rotation coordinator for the default video device.
            createRotationCoordinator(for: defaultCamera)
            
            isSetUp = true
        } catch {
            throw CameraError.setupFailed
        }
    }

    // Adds an input to the capture session to connect the specified capture device.
    @discardableResult
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw CameraError.addInputFailed
        }
        return input
    }
    
    // Adds an output to the capture session to connect the specified capture device, if allowed.
    private func addOutput(_ output: AVCaptureOutput) throws {
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            throw CameraError.addOutputFailed
        }
    }
    
    // The device for the active video input.
    private var currentDevice: AVCaptureDevice {
        guard let device = activeVideoInput?.device else {
            fatalError("No device found for current video input.")
        }
        return device
    }
    
    // MARK: - Device selection
    
    /// Changes the capture device that provides video input.
    ///
    /// The app calls this method in response to someone tapping the button in the UI to change cameras.
    /// The implementation switches between the front and rear cameras, and
    func selectNextVideoDevice() {
        // The array of available video-capture devices.
        let videoDevices = deviceLookup.cameras

        // Find the index of the currently selected video device.
        let selectedIndex = videoDevices.firstIndex(of: currentDevice) ?? 0
        // Get the next index.
        var nextIndex = selectedIndex + 1
        // Wrap around if the next index is invalid.
        if nextIndex == videoDevices.endIndex {
            nextIndex = 0
        }
        
        let nextDevice = videoDevices[nextIndex]
        // Change the session's active capture device.
        changeCaptureDevice(to: nextDevice)
        
        // Set the zoom factor.
        zoomFactor = nextDevice.videoZoomFactor
        minZoomFactor = nextDevice.minAvailableVideoZoomFactor
        
        // The app only calls this method in response to someone requesting to switch cameras.
        // Set the new selection as the person's preferred camera.
        AVCaptureDevice.userPreferredCamera = nextDevice
    }
    
    // Changes the device the service uses for video capture.
    private func changeCaptureDevice(to device: AVCaptureDevice) {
        // The service needs to have a valid video input prior to calling this method.
        guard let currentInput = activeVideoInput else { fatalError() }
        
        // Bracket the following configuration in a begin/commit configuration pair.
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Remove the existing video input before attempting to connect a new one.
        captureSession.removeInput(currentInput)
        do {
            // Attempt to connect a new input and device to the capture session.
            activeVideoInput = try addInput(for: device)
            // Configure a new rotation coordinator for the new device.
            createRotationCoordinator(for: device)
        } catch {
            // Reconnect the existing camera on failure.
            captureSession.addInput(currentInput)
        }
    }
    
    // MARK: Zoom
    func updateMagnification(for zoomType: CameraZoomType, by scale: Double = 0.2) {
        try? currentDevice.lockForConfiguration()
        let magnification = (zoomType == .increase ? 1.0 : -1.0) * scale
        var newZoomFactor = currentDevice.videoZoomFactor + magnification
        newZoomFactor = max(min(newZoomFactor, self.maxZoomFactor), self.minZoomFactor)
        newZoomFactor = Double(round(10 * newZoomFactor) / 10)
        currentDevice.videoZoomFactor = newZoomFactor
        currentDevice.unlockForConfiguration()
        self.zoomFactor = newZoomFactor
    }
    
    // MARK: - Rotation handling
    
    /// Create a new rotation coordinator for the specified device and observe its state to monitor rotation changes.
    private func createRotationCoordinator(for device: AVCaptureDevice) {
        // Create a rotation coordinator for this device.
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: videoPreviewLayer)
        
        // Set the initial rotation state on the preview and the output connections.
        updatePreviewRotation(rotationCoordinator.videoRotationAngleForHorizonLevelPreview)
        updateCaptureRotation(rotationCoordinator.videoRotationAngleForHorizonLevelCapture)
        
        // Cancel the previous observations.
        rotationObservers.removeAll()
        
        // Add observers to monitor future changes.
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                // Update the capture preview rotation.
                Task { await self.updatePreviewRotation(angle) }
            }
        )
        
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                // Update the capture preview rotation.
                Task { await self.updateCaptureRotation(angle) }
            }
        )
    }
    
    private func updatePreviewRotation(_ angle: CGFloat) {
        let previewLayer = videoPreviewLayer
        Task { @MainActor in
            // Set the initial rotation angle on the video preview.
            previewLayer.connection?.videoRotationAngle = angle
        }
    }
    
    private func updateCaptureRotation(_ angle: CGFloat) {
        // Update the orientation for all output services.
        outputServices.forEach { $0.setVideoRotationAngle(angle) }
        cameraOrientation = CameraOrientation(videoRotationAngle: angle, front: currentDevice.position == .front)
    }
    
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // Access the capture session's connected preview layer.
        guard let previewLayer = captureSession.connections.compactMap({ $0.videoPreviewLayer }).first else {
            fatalError("The app is misconfigured. The capture session should have a connection to a preview layer.")
        }
        return previewLayer
    }
    
    // MARK: - Movie capture
    /// Starts recording video. The video records until someone stops the recording,
    /// which calls the following `stopRecording()` method.
    func startRecording() {
        movieCapture.startRecording()
    }
    
    /// Stops the recording and returns the captured movie.
    func stopRecording() async throws -> Movie {
        try await movieCapture.stopRecording()
    }
    
    // MARK: - DockKit tracking delegate
    /// Set the tracking delegate.
    func setTrackingServiceDelegate(_ delegate: DockAccessoryTrackingDelegate) {
        trackingDelegate = delegate
    }
    
    // MARK: - Miscellaneous
    /// Convert a point from the view-space coordinates to the device coordinates, where (0,0) is top left and (1,1) is bottom right.
    func devicePointConverted(from point: CGPoint) -> CGPoint {
        // The point this call receives is in view-space coordinates. Convert this point to device coordinates.
        let size = videoPreviewLayer.preferredFrameSize()
        
        let pointInDeviceCoordinates = CGPoint(x: point.x / size.width, y: point.y / size.height)
        
        let convertedPointInDeviceCoordinates = convertFromCorrected(point: pointInDeviceCoordinates)
        
        return convertedPointInDeviceCoordinates
    }
    
    func layerRectConverted(from rect: CGRect) -> CGRect {
        let size = videoPreviewLayer.preferredFrameSize()
        
        let convertedRect = convertToCorrected(rect: rect)
        
        let convertedRectInLayer = CGRect(x: convertedRect.origin.x * size.width,
                                          y: convertedRect.origin.y * size.height,
                                          width: convertedRect.size.width * size.width,
                                          height: convertedRect.size.height * size.height)
        
        return convertedRectInLayer
    }
    
    /// `Rect` is a normalized rectangle in the current camera orientation where (0,0) is top left and (1,1) is bottom right.
    /// Correct this rectangle to the camera preview orientation (portrait).
    func convertToCorrected(rect: CGRect) -> CGRect {
        switch cameraOrientation {
        case .portrait:
            return rect
        case .portraitUpsideDown:
            return CGRect(x: 1 - rect.minX - rect.width,
                          y: 1 - rect.minY - rect.height,
                          width: rect.width,
                          height: rect.height)
        case .landscapeRight:
            return CGRect(x: 1 - rect.minY - rect.height,
                          y: rect.minX,
                          width: rect.height,
                          height: rect.width)
        case .landscapeLeft:
            return CGRect(x: rect.minY,
                          y: 1 - rect.minX - rect.width,
                          width: rect.height,
                          height: rect.width)
        case .unknown:
            return rect
        }
    }
    
    /// This point is a normalized point in the camera preview orientation (portrait).
    /// Correct this point to the current camera orientation.
    func convertFromCorrected(point: CGPoint) -> CGPoint {
        switch cameraOrientation {
        case .portrait:
            return point
        case .portraitUpsideDown:
            return CGPoint(x: 1 - point.x, y: 1 - point.y)
        case .landscapeRight:
            return CGPoint(x: point.y, y: 1 - point.x)
        case .landscapeLeft:
            return CGPoint(x: 1 - point.y, y: point.x)
        case .unknown:
            return point
        }
    }
        
}

