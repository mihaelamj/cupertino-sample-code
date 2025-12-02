/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages the app's audio-visual capture session, its various capture devices,
 and notifies the app's interface as the capture session's state changes.
*/

import AVFoundation

/// Manages a capture session and coordinates with the app's other types.
///
/// This type coordinates interactions with the following items:
/// - Media inputs like cameras and microphones
/// - Capturer types that save photo, video, and audio files
/// - Visual effects for photos and video recordings
/// - Tag: CaptureManager
class CaptureManager: NSObject, ObservableObject {

    // MARK: - Main properties

    /// Represents the app's interaction with a device's camera and microphone
    let session = AVCaptureSession()

    /// Provides a small video feed from a camera.
    let previewLayer: AVCaptureVideoPreviewLayer

    /// The current video capture input of the session.
    ///
    /// When you change the property, it adds the new input to the
    /// capture session, which replaces its current input, if applicable.
    /// - Tag: activeInput
    internal var activeInput: AVCaptureDeviceInput? {
        willSet {
            if let oldInput = activeInput {
                session.removeInput(oldInput)
            }
        }
        didSet {
            if let newInput = activeInput {
                session.addInput(newInput)
            }
            isActive = (activeInput != nil)
        }
    }

    /// Returns a Boolean value that indicates whether a capture device is the
    /// different as the capture session's current device.
    ///
    /// - Parameter device: A capture device instances.
    func cameraIsNew(_ device: AVCaptureDevice) -> Bool {
        return device.uniqueID != activeInput?.device.uniqueID
    }

    // MARK: - Observers and published properties

    /// A Boolean value that indicates whether the capture session is active.
    /// - Tag: isActive
    @Published var isActive = false

    /// An observer that monitors the activity of the video effects of a camera.
    var videoEffectsObvserver = VideoEffectsObserver()

    /// An observer that listens to notifications for one camera at a time.
    var notificationObserver = CaptureManager.makeNotificationObserver()

    /// An observer that monitors a type property that indicates
    /// which camera the system prefers.
    var preferredCameraObserver = PreferredCameraObserver()

    // MARK: - Initializer

    /// Connects the capture session to the preview layer, and registers for
    /// various notifications related to device and feature updates.
    override init() {
        // Connects the preview layer to the instance's capture session.
        previewLayer = AVCaptureVideoPreviewLayer(session: session)

        // Calls the superclass's initializer after initializing all of this
        // instance's properties.
        super.init()

        preferredCameraObserver.handler = updateSystemPreferredCamera(_:)
    }

    /// Responds to a change with the system's preferred camera by setting the
    /// new camera device as the capture session's video input.
    ///
    /// - Parameter camera: The system's new preferred camera device.
    private func updateSystemPreferredCamera(_ camera: AVCaptureDevice) {
        let description = String(describing: camera)
        print("The system's preferred camera is now: \(description)")

        guard cameraIsNew(camera) else { return }

        // Activates the new camera.
        DispatchQueue.main.async {
            self.setActiveVideoInput(camera)
        }
    }
}

// MARK: - Session start & stop

extension CaptureManager {

    /// Starts the capture session, if it's not currently running.
    public func startIfNeeded() {
        if !session.isRunning {
            Task { await start() }
        }
    }

    /// Starts the capture session if the app has or gets permission.
    public func start() async {

        guard await checkOrAuthorize(for: .video) else {
            print("Can't get authorization for video recording.")
            return
        }

        print("Starting capture session...")
        session.startRunning()
    }

    /// Stops the capture session
    public func stop() {
        print("Ending capture session.")
        session.stopRunning()
    }
}

// MARK: - Inputs and outputs

extension CaptureManager {

    /// Assigns a camera input device to the capture session.
    ///
    /// - Parameters:
    ///   - camera: A video capture device instance that represents a camera.
    ///   - isUserPreferredCamera: A Boolean value that indicates whether a
    ///   person made the selection.
    ///
    /// - Returns: A Boolean value that indicates whether the method successfuly
    /// assigns the `camera` as an input to the capture session.
    /// - Tag: CaptureManager.setActiveVideoInput
    @discardableResult
    public func setActiveVideoInput(_ camera: AVCaptureDevice,
                                    isUserPreferredCamera: Bool = false) -> Bool {
        // Marks the start of the capture session configuration.
        session.beginConfiguration()

        // Calls these methods after this method returns.
        defer {
            // Ends the capture session configuration and restarts, if applicable.
            session.commitConfiguration()
            startIfNeeded()
        }

        let name = camera.localizedName
        print("Setting video input to: \(name).")

        // Creates a video input with the camera.
        guard let videoInput = try? AVCaptureDeviceInput(device: camera) else {
            print("Couldn't make an input from: \(name).")
            return false
        }

        // Checks whether the capture session accepts the new camera as an input.
        guard session.canAddInput(videoInput) else {
            print("Capture session rejected '\(name)' as an input.")
            return false
        }

        // Adds the new camera input to the capture session.
        activeInput = videoInput

        // Informs the capture device type that this instance is a person's choice.
        if isUserPreferredCamera {
            AVCaptureDevice.userPreferredCamera = camera
        }

        // Updates observers so they monitor the new camera.
        observeCamera(camera)
        return true
    }

    /// Adds an output type to the capture session, such as a movie or photo file.
    ///
    /// - Parameter output: An output type for a capture session.
    public func addOutput(_ output: AVCaptureOutput) {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        let outputDescription = String(describing: output)
        guard session.canAddOutput(output) else {
            print("Capture session rejected output: \(outputDescription).")
            return
        }

        session.addOutput(output)
        print("Capture session adding output: \(outputDescription).")
    }
}

// MARK: - Authorization

extension CaptureManager {

    /// Returns a Boolean value that indicates whether the person running the
    /// app gives permission to access a media type.
    ///
    /// - Parameter mediaType: A media type that requires permission from
    /// the person running the app, typically for video or audio.
    private func checkOrAuthorize(for mediaType: AVMediaType) async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: mediaType) == .authorized {
            return true
        } else {
            print("requesting user authorization for AVMediaType: \(String(describing: mediaType))")
            return await AVCaptureDevice.requestAccess(for: mediaType)
        }
    }
}
