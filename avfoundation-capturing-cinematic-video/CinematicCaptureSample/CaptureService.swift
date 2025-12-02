/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages a capture session and its inputs and outputs.
*/

import Foundation
@preconcurrency import AVFoundation
import Combine

@Observable
class CinematicMetadataManager {
    
    var cinematicFocusMetadata: [CinematicFocusMetadata] = []
    
}
/// An actor that manages the capture pipeline, which includes the capture session, device inputs, and capture outputs.
/// The app defines it as an `actor` type to ensure that all camera operations happen off of the `@MainActor`.
actor CaptureService: NSObject {

    /// A value that indicates whether the capture service is idle or capturing a movie.
    @Published private(set) var captureActivity: CaptureActivity = .idle
    /// A Boolean value that indicates whether a higher priority event, like receiving a phone call, interrupts the app.
    @Published private(set) var isInterrupted = false
        
    nonisolated let metadataManager = CinematicMetadataManager()
    
    // The app's capture session.
    private let captureSession = AVCaptureSession()
    
    // An object that manages the app's video capture behavior.
    private let movieCapture = MovieCapture()
    
    // An internal collection of output services.
    private var outputServices: [any OutputService] { [movieCapture] }
    
    // The video input for the currently selected device camera.
    private var activeVideoInput: AVCaptureDeviceInput?
    
    // The mode of capture, either PreviewLayer or VDO. Defaults to PreviewLayer.
    private(set) var captureMode = CaptureMode.previewLayer
    
    // An object the service uses to retrieve capture devices.
    private let deviceLookup = DeviceLookup()
    
    // An object that monitors the state of the system-preferred camera.
    private let systemPreferredCamera = SystemPreferredCameraObserver()
    
    // An object that monitors video device rotations.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var rotationObservers = [AnyObject]()
    private let previewLayer: AVSampleBufferDisplayLayer

    // A Boolean value that indicates whether the actor finished its required configuration.
    private var isSetUp = false
    
    // A metadata output.
    private var metadataOutput = AVCaptureMetadataOutput()
    
    private var metadataObjectsCache = [AVMetadataObject]()
    
    // A video data output.
    var videoOutput = AVCaptureVideoDataOutput()
    
    // A serial dispatch queue.
    private let sessionQueue = DispatchSerialQueue(label: "sessionQueue")
    
    // Sets the session queue as the actor's executor.
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    /// Aperture values.
    var simulatedAperture: Float = -1.0
    var maxSimulatedAperture: Float = 12.5
    var minSimulatedAperture: Float = 2.5
    
    init(previewLayer: AVSampleBufferDisplayLayer) {
        self.previewLayer = previewLayer
    }
    
    // MARK: - Authorization
    /// A Boolean value that indicates whether a person authorizes this app to use
    /// device cameras and microphones. If they haven't previously authorized the
    /// app, querying this property prompts them for authorization.
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            // Determine whether a person previously authorized camera access.
            var isAuthorized = status == .authorized
            // If the system hasn't determined their authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }
    
    // MARK: - Capture session life cycle
    func start() async throws {
        // Set initial operating state.
        captureMode = .previewLayer
        
        // Exit early if not authorized or the session is already running.
        guard await isAuthorized, !captureSession.isRunning else { return }
        // Configure the session and start it.
        try setUpSession()
        captureSession.startRunning()
    }
    
    // MARK: - Capture setup
    // Performs the initial capture session configuration.
    private func setUpSession() throws {
        // Return early if already set up.
        guard !isSetUp else { return }

        // Observe internal state and notifications.
        observeOutputServices()
        observeNotifications()
        
        do {
            // Retrieve the default camera and microphone.
            let defaultCamera = try deviceLookup.defaultCamera
            let defaultMic = try deviceLookup.defaultMic

            // Add inputs for the default camera and microphone devices.
            activeVideoInput = try addInput(for: defaultCamera)
            let audioInput = try addInput(for: defaultMic)
            // Enable spatial audio.
            if audioInput.isMultichannelAudioModeSupported(.firstOrderAmbisonics) {
                audioInput.multichannelAudioMode = .firstOrderAmbisonics
            }

            // Configure the session preset based on the current capture mode.
            captureSession.sessionPreset = .high
            try addOutput(movieCapture.output)
            
            // Enable video stabilization if the connection supports it.
            if let connection = movieCapture.output.connection(with: .video), connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .cinematicExtended
            }
            
            // Sets the active format; prefers 10 bit.
            let format = setActiveFormat()
            setupCinematicCapture(format)
            
            // Add metadata and VDO output.
            metadataVDOSetup()
            
            // Monitor the system-preferred camera state.
            monitorSystemPreferredCamera()
            // Configure a rotation coordinator for the default video device.
            createRotationCoordinator(for: defaultCamera)
            
            isSetUp = true
        } catch {
            throw CameraError.setupFailed
        }
    }

    // MARK: - Metadata and VDO setup
    // Performs the initial capture session configuration.
    private func metadataVDOSetup() {
        captureSession.removeOutput(videoOutput)
        captureSession.removeOutput(metadataOutput)
        
        captureSession.addOutput(metadataOutput)
        metadataOutput.metadataObjectTypes = metadataOutput.requiredMetadataObjectTypesForCinematicVideoCapture
        metadataOutput.setMetadataObjectsDelegate(self, queue: sessionQueue)
        
        captureSession.addOutput(videoOutput)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_Lossless_420YpCbCr10PackedBiPlanarVideoRange]
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    }
    
    func updateVDORotation(angle: CGFloat) {

        guard let videoConnection = videoOutput.connection(with: .video) else {
            fatalError("No video connection")
        }

        guard let videoInput = activeVideoInput else {
            fatalError("No video input")
        }

        do {
            try currentDevice.lockForConfiguration()
            // Determine whether to mirror the video image.
            let isVideoMirrored = videoInput.device.position == .front

            if videoConnection.isVideoRotationAngleSupported(angle) {
                videoConnection.videoRotationAngle = angle
            }

            if videoConnection.isVideoMirroringSupported && isVideoMirrored {
                videoConnection.isVideoMirrored = isVideoMirrored
            }
            currentDevice.unlockForConfiguration()
        } catch {
            fatalError("Couldn't update AVCaptureVideoDataOutput connection rotation.")
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
    /// The app calls this method in response to the user tapping the button in the UI to change cameras.
    /// The implementation switches between the front and rear cameras.
    func selectNextVideoDevice() {
        // The array of available video capture devices.
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
        
        // The app only calls this method when the person requests to switch cameras.
        // Set the new selection as the person's preferred camera.
        AVCaptureDevice.userPreferredCamera = nextDevice
    }
    
    // Changes the device the service uses for video capture.
    private func changeCaptureDevice(to device: AVCaptureDevice) {
        // The service must have a valid video input prior to calling this method.
        guard let currentInput = activeVideoInput else { fatalError() }
        
        // Bracket the following configuration in a begin-commit configuration pair.
        captureSession.beginConfiguration()
        
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
        captureSession.commitConfiguration()

        // Sets the active format; prefers 10 bit.
        let format = setActiveFormat()
        setupCinematicCapture(format)
    }
    
    /// Monitors changes to the system's preferred camera selection.
    private func monitorSystemPreferredCamera() {
        Task {
            // An object that monitors changes to system-preferred camera (SPC) value.
            for await camera in systemPreferredCamera.changes {
                // If the SPC isn't the currently selected camera, attempt to change to that device.
                if let camera, currentDevice != camera {
                    logger.debug("Switching camera selection to the system-preferred camera.")
                    changeCaptureDevice(to: camera)
                }
            }
        }
    }
    
    // MARK: - Rotation handling
    
    /// Create a new rotation coordinator for the specified device and observe its state to monitor rotation changes.
    private func createRotationCoordinator(for device: AVCaptureDevice) {
        // Create a new rotation coordinator for this device.
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)

        // Set initial rotation state on the preview and output connections.
        updatePreviewRotation(rotationCoordinator.videoRotationAngleForHorizonLevelPreview)
        updateCaptureRotation(rotationCoordinator.videoRotationAngleForHorizonLevelCapture)
        
        // Cancel previous observations.
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
        updateVDORotation(angle: angle)
    }
    
    private func updateCaptureRotation(_ angle: CGFloat) {
        // Update the orientation for all output services.
        outputServices.forEach { $0.setVideoRotationAngle(angle) }
    }

    // MARK: - Movie capture
    /// Starts recording video. The video records until the person stops recording,
    /// which calls the following `stopRecording()` method.
    func startRecording() {
        movieCapture.startRecording()
    }
    
    /// Stops the recording and returns the captured movie.
    func stopRecording() async throws -> Movie {
        try await movieCapture.stopRecording()
    }
    
    func setupCinematicCapture(_ format: AVCaptureDevice.Format) {
        // The service must have a valid video input prior to calling this method.
        guard let currentInput = activeVideoInput else { fatalError() }
        do {
            try currentDevice.lockForConfiguration()
            if currentInput.isCinematicVideoCaptureSupported {
                currentInput.isCinematicVideoCaptureEnabled = true
                if simulatedAperture < 0 {
                    simulatedAperture = format.defaultSimulatedAperture
                }
                maxSimulatedAperture = format.maxSimulatedAperture
                minSimulatedAperture = format.minSimulatedAperture
                currentInput.simulatedAperture = simulatedAperture
            } else {
                fatalError("Cinematic video capture is not supported on this device.")
            }
            currentDevice.unlockForConfiguration()
        } catch {
            fatalError("Couldn't setup cinematic capture")
        }
    }
    
    func setSimulatedAperture(_ aperture: Float) {
        activeVideoInput?.simulatedAperture = aperture
        simulatedAperture = aperture
    }
    
    func tapPreview(at point: CGPoint) {
        
        guard let device = activeVideoInput?.device else { return }
        
        try! device.lockForConfiguration()
        
        if let metadata = findMetadataObject(at: point) {
            let focusMode: AVCaptureDevice.CinematicVideoFocusMode = metadata.cinematicVideoFocusMode == .weak ? .strong : .weak
            device.setCinematicVideoTrackingFocus(detectedObjectID: metadata.objectID, focusMode: focusMode)
        } else {
            device.setCinematicVideoTrackingFocus(at: pointInMetadataSpace(from: point), focusMode: .weak)
        }

        device.unlockForConfiguration()
    }
    
    func longPressPreview(at point: CGPoint) {
        
        guard let device = activeVideoInput?.device else { return }
        
        try! device.lockForConfiguration()
        activeVideoInput?.device.setCinematicVideoFixedFocus(at: pointInMetadataSpace(from: point), focusMode: .strong)
        device.unlockForConfiguration()
    }
    
    private func findMetadataObject(at normalizedPointInView: CGPoint) -> AVMetadataObject? {
        
        var metadataFound: AVMetadataObject?
        for metadata in metadataObjectsCache {
            if metadata.bounds.contains(pointInMetadataSpace(from: normalizedPointInView)) {
                metadataFound = metadata
                break
            }
        }
        
        return metadataFound
    }
    
    private func pointInMetadataSpace(from pointInViewSpace: CGPoint) -> CGPoint {
        let fullFrameInOutputCoordinates = videoOutput.outputRectConverted(fromMetadataOutputRect: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 1)))
        let pointInOutputCoordinates = CGPoint(
            x: pointInViewSpace.x * fullFrameInOutputCoordinates.size.width,
            y: pointInViewSpace.y * fullFrameInOutputCoordinates.height
        )
        return videoOutput.metadataOutputRectConverted(fromOutputRect: CGRect(x: pointInOutputCoordinates.x, y: pointInOutputCoordinates.y, width: 0, height: 0)).origin
    }
    
    /// Sets the active format; prefers 10 bit.
    func setActiveFormat() -> AVCaptureDevice.Format {
        // Bracket the following configuration in a begin-commit configuration pair.
        captureSession.beginConfiguration()
        guard let format = currentDevice.activeFormat10BitCinematicVariant else {
            fatalError("No 10bit active format found on device.")
        }
        
        do {
            try currentDevice.lockForConfiguration()
            currentDevice.activeFormat = format
            currentDevice.unlockForConfiguration()
        } catch {
            fatalError("Failed to lock device for configuration")
        }
        captureSession.commitConfiguration()
        return format
    }

    private func observeOutputServices() {
        movieCapture.$captureActivity.assign(to: &$captureActivity)
    }
    
    /// Observe capture-related notifications.
    private func observeNotifications() {
        Task {
            for await reason in NotificationCenter.default.notifications(named: AVCaptureSession.wasInterruptedNotification)
                .compactMap({ $0.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject? })
                .compactMap({ AVCaptureSession.InterruptionReason(rawValue: $0.integerValue) }) {
                /// Set the `isInterrupted` state as appropriate.
                isInterrupted = [.audioDeviceInUseByAnotherClient, .videoDeviceInUseByAnotherClient].contains(reason)
            }
        }
        
        Task {
            // Await notification of the end of an interruption.
            for await _ in NotificationCenter.default.notifications(named: AVCaptureSession.interruptionEndedNotification) {
                isInterrupted = false
            }
        }
        
        Task {
            for await error in NotificationCenter.default.notifications(named: AVCaptureSession.runtimeErrorNotification)
                .compactMap({ $0.userInfo?[AVCaptureSessionErrorKey] as? AVError }) {
                // If the system resets media services, the capture session stops running.
                if error.code == .mediaServicesWereReset {
                    if !captureSession.isRunning {
                        captureSession.startRunning()
                    }
                }
            }
        }
    }
}

extension CaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        assumeIsolated { isolatedSelf in
            isolatedSelf.previewLayer.sampleBufferRenderer.enqueue(sampleBuffer)
        }
    }
}

extension CaptureService: AVCaptureMetadataOutputObjectsDelegate {
    
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        assumeIsolated { isolatedSelf in
            
            isolatedSelf.metadataObjectsCache = metadataObjects
            
            var cinematicFocusMetadataObjects = [CinematicFocusMetadata]()
            for metadataObject in metadataObjects {

                // Don't draw bodies in the preview as otherwise the preview gets too busy.
                if metadataObject.type == .catBody || metadataObject.type == .dogBody || metadataObject.type == .humanBody {
                    continue
                }
                
                let boundsInOutputCoordinates = isolatedSelf.videoOutput.outputRectConverted(fromMetadataOutputRect: metadataObject.bounds)
                let fullFrameInOutputCoordinates = isolatedSelf.videoOutput.outputRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
                let layerBoundsNormalized = CGRect(x: boundsInOutputCoordinates.origin.x / fullFrameInOutputCoordinates.width,
                                                   y: boundsInOutputCoordinates.origin.y / fullFrameInOutputCoordinates.height,
                                                   width: boundsInOutputCoordinates.size.width / fullFrameInOutputCoordinates.width,
                                                   height: boundsInOutputCoordinates.size.height / fullFrameInOutputCoordinates.size.height)
                
                let cinematicFocusMetadata = CinematicFocusMetadata(metadataObject: metadataObject, layerBoundsNormalized: layerBoundsNormalized)
                cinematicFocusMetadataObjects.append(cinematicFocusMetadata)
            }
            
            isolatedSelf.metadataManager.cinematicFocusMetadata = cinematicFocusMetadataObjects
        }
    }
}
