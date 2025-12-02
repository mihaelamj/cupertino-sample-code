/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The object that manages the capture session.
*/

import Foundation
import AVFoundation
import Combine

@MainActor
class Camera: ObservableObject {
    
    enum Error: Swift.Error {
        case noVideoDeviceAvailable
        case noAudioDeviceAvailable
        case setupFailed
    }
    
    enum State: @unchecked Sendable {
        case unknown
        case unauthorized
        case failed
        case running
        case stopped
    }
    
    private(set) var isSetup = false
    private(set) var isAuthorized = false
    private(set) var isRunning = false
    
    // The app's capture session.
    private let session = AVCaptureSession()
    
    private var activeVideoInput: AVCaptureDeviceInput? {
        didSet {
            guard let device = activeVideoInput?.device else { return }
            updateVideoFormats(for: device)
            updateVideoEffectsState(for: device)
            if device.uniqueID != selectedVideoDevice.id {
                selectedVideoDevice = Device(id: device.uniqueID, name: device.localizedName)
            }
        }
    }
    private var activeAudioInput: AVCaptureDeviceInput? {
        didSet {
            guard let device = activeAudioInput?.device, device.uniqueID != selectedVideoDevice.id else { return }
            selectedAudioDevice = Device(id: device.uniqueID, name: device.localizedName)
        }
    }
    
    // Discovery sessions to find video and audio devices.
    private var videoDiscoverySession: AVCaptureDevice.DiscoverySession!
    private var audioDiscoverySession: AVCaptureDevice.DiscoverySession!
    
    // An object that monitors the system's preferred camera.
    private let preferredCameraObserver = PreferredCameraObserver()
    // An object that monitors the state of system video effects.
    private let videoEffectsObserver = VideoEffectsObserver()
    
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: - @Published UI Properties
    @Published private(set) var state = State.unknown
    
    @Published var isAutomaticCameraSelectionEnabled = true
    
    @Published private(set) var videoDevices = [Device]()
    @Published private(set) var audioDevices = [Device]()
    @Published private(set) var videoFormats = [VideoFormat]()
    
    @Published var selectedVideoDevice = Device.invalid
    @Published var selectedAudioDevice = Device.invalid
    @Published var selectedVideoFormat = VideoFormat.invalid
    
    @Published private(set) var isCenterStageSupported = false
    @Published var isCenterStageEnabled = false {
        didSet {
            guard isCenterStageEnabled != AVCaptureDevice.isCenterStageEnabled else { return }
            AVCaptureDevice.centerStageControlMode = .cooperative
            AVCaptureDevice.isCenterStageEnabled = isCenterStageEnabled
        }
    }
    @Published private(set) var isPortraitEffectSupported = false
    @Published private(set) var isPortraitEffectEnabled = false
    @Published private(set) var isStudioLightSupported = false
    @Published private(set) var isStudioLightEnabled = false
    
    // MARK: - Capture Preview
    /// A view that provides a preview of the captured content.
    lazy var preview: CameraPreview = {
        CameraPreview(session: session)
    }()
    
    // MARK: - Initialization
    init() {
        // Observe changes to the system-preferred camera, and update the device selection accordingly.
        preferredCameraObserver.$systemPreferredCamera.dropFirst().removeDuplicates().compactMap({ $0 }).sink { [weak self] captureDevice in
            guard let self = self, self.isSetup else { return }
            Task { await self.systemPreferredCameraChanged(to: captureDevice) }
        }.store(in: &subscriptions)
        
        // Monitor the state of system video effects and update the camera's published properties.
        videoEffectsObserver.$isCenterStageEnabled.receive(on: RunLoop.main).assign(to: \.isCenterStageEnabled, on: self).store(in: &subscriptions)
        videoEffectsObserver.$isPortraitEffectEnabled.receive(on: RunLoop.main).assign(to: \.isPortraitEffectEnabled, on: self).store(in: &subscriptions)
        videoEffectsObserver.$isStudioLightEnabled.receive(on: RunLoop.main).assign(to: \.isStudioLightEnabled, on: self).store(in: &subscriptions)
        
        // Observe changes to device selections from the UI.
        $selectedVideoDevice.merge(with: $selectedAudioDevice).dropFirst().removeDuplicates().sink { [weak self] device in
            // Return early if the camera hasn't finished its set up.
            guard let self = self, self.isSetup else { return }
            self.selectDevice(device)
        }.store(in: &subscriptions)
        
        // Observe changes to video format from the UI.
        $selectedVideoFormat.dropFirst().sink { [weak self] format in
            self?.selectFormat(format)
        }.store(in: &subscriptions)
        
        // If the user enables the "Automatic Camera Selection" checkbox, select the SPC (if not already selected).
        $isAutomaticCameraSelectionEnabled.sink { [weak self] isEnabled in
            guard isEnabled, let systemPreferredCamera = AVCaptureDevice.systemPreferredCamera else { return }
            Task { await self?.selectCaptureDevice(systemPreferredCamera) }
        }.store(in: &subscriptions)
    }
    
    // MARK: - Start Up
    /// Starts the camera and begins the stream of data.
    func start() async {
        guard await authorize() else {
            self.state = .unauthorized
            return
        }
        do {
            try setup()
            startSession()
        } catch {
            state = .failed
        }
    }
    
    // MARK: - Authorization
    // Verify that the user allows this app to access capture devices.
    private func authorize() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        // Determine if the user has previously authorized camera access.
        isAuthorized = status == .authorized
        // If the system hasn't determined the user's authorization status,
        // explicitly prompt them for approval.
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        return isAuthorized
    }
    
    // MARK: - Capture Setup
    // Configures the capture session.
    private func setup() throws {
        // Return early if already set up.
        guard !isSetup else { return }
        
        // Set up discovery sessions to find camera and microphone devices.
        setupDeviceDiscovery()
        
        session.beginConfiguration()
        
        // Use the `.high` session preset.
        session.sessionPreset = .high
        try setupInputs()
        
        session.commitConfiguration()
        isSetup = true
    }
    
    private func setupDeviceDiscovery() {
        // Observe device cameras. Specify `.externalUnknown` to access an iPhone camera as an `AVCaptureDevice`.
        videoDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                                                                 mediaType: .video,
                                                                 position: .unspecified)
        // Observe device microphones. Specify `.externalUnknown` to access an iPhone microphone as an `AVCaptureDevice`.
        audioDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .externalUnknown],
                                                                 mediaType: .audio,
                                                                 position: .unspecified)
        videoDiscoverySession.publisher(for: \.devices).sink { devices in
            self.videoDevices = devices.map { Device(id: $0.uniqueID, name: $0.localizedName) }
        }.store(in: &subscriptions)
        
        audioDiscoverySession.publisher(for: \.devices).sink { devices in
            self.audioDevices = devices.map { Device(id: $0.uniqueID, name: $0.localizedName) }
        }.store(in: &subscriptions)
    }
    
    private func setupInputs() throws {
        // Create an input for the default camera and connect it to the session.
        let videoCaptureDevice = try defaultVideoCaptureDevice
        activeVideoInput = try addInput(for: videoCaptureDevice)
        
        isCenterStageEnabled = videoCaptureDevice.isCenterStageActive
        isPortraitEffectEnabled = videoCaptureDevice.isPortraitEffectActive
        isStudioLightEnabled = videoCaptureDevice.isStudioLightActive
        
        // Create an input for the default microphone and connect it to the session.
        let audioDevice = try defaultAudioCaptureDevice
        activeAudioInput = try addInput(for: audioDevice)
    }
    
    private var defaultVideoCaptureDevice: AVCaptureDevice {
        get throws {
            // Access the system's preferred camera.
            if let device = AVCaptureDevice.systemPreferredCamera {
                return device
            } else {
                // No camera is available on the host system.
                throw Error.noVideoDeviceAvailable
            }
        }
    }
    
    private var defaultAudioCaptureDevice: AVCaptureDevice {
        get throws {
            guard let audioDevice = audioDiscoverySession.devices.first else {
                throw Error.noAudioDeviceAvailable
            }
            return audioDevice
        }
    }
    
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            throw Error.setupFailed
        }
        return input
    }
    
    // Reset the capture session to its default configuration.
    private func resetToDefaultDevices() {
        session.beginConfiguration()
        // Ensure the begin/commit pair gets invoked in all cases.
        defer {
            session.commitConfiguration()
        }
        // Remove all current inputs.
        session.inputs.forEach { input in
            session.removeInput(input)
        }
        do {
            try setupInputs()
        } catch {
            print(error)
        }
    }
    
    // MARK: - Capture Session Start
    private func startSession() {
        Task.detached(priority: .userInitiated) {
            guard await !self.isRunning else { return }
            self.session.startRunning()
            await MainActor.run {
                self.isRunning = self.session.isRunning
                self.state = .running
            }
        }
    }
    
    // MARK: - Device Selection Handling
    // User device selections call this method.
    func selectDevice(_ device: Device) {
        Task {
            // Convert the Device to an AVCaptureDevice.
            let captureDevice = findCaptureDevice(for: device)
            await selectCaptureDevice(captureDevice, isUserSelection: true)
        }
    }
    
    private func findCaptureDevice(for device: Device) -> AVCaptureDevice {
        let allDevices = videoDiscoverySession.devices + audioDiscoverySession.devices
        guard let device = allDevices.first(where: { $0.uniqueID == device.id }) else {
            fatalError("Couldn't find capture device for Device selection.")
        }
        return device
    }
    
    // The app calls this method when the system-preferred camera changes.
    private func systemPreferredCameraChanged(to captureDevice: AVCaptureDevice) async {
        
        // If the SPC changes due to a device disconnection, reset the app
        // to its default device selections.
        guard isActiveVideoInputDeviceConnected else {
            resetToDefaultDevices()
            return
        }
        
        // If the "Automatic Camera Selection" checkbox is in an enabled state,
        // automatically select the new capture device.
        if isAutomaticCameraSelectionEnabled {
            await selectCaptureDevice(captureDevice)
        }
    }
    
    private var isActiveVideoInputDeviceConnected: Bool {
        activeVideoInput?.device.isConnected ?? false
    }
    
    // This method performs the actual session reconfiguration to select the new device.
    private func selectCaptureDevice(_ device: AVCaptureDevice, isUserSelection: Bool = false) async {
        
        // Return early if the device is already selected.
        guard activeVideoInput?.device != device, activeAudioInput?.device != device else { return }
        
        let mediaType = device.hasMediaType(.video) ? AVMediaType.video : .audio
        guard let currentInput = mediaType == .video ? activeVideoInput : activeAudioInput else { return }
        
        session.beginConfiguration()
        // Ensure the begin/commit pair gets invoked in all cases.
        defer {
            session.commitConfiguration()
        }
        
        do {
            // Remove the current input from the session.
            session.removeInput(currentInput)
            
            // Attempt to add the new device to the capture session.
            let newInput = try addInput(for: device)
            
            // Camera
            if mediaType == .video {
                activeVideoInput = newInput
                if isUserSelection {
                    // If the device change is due to user selection, set the UPC value,
                    // which updates the state of the system-preferred camera.
                    AVCaptureDevice.userPreferredCamera = device
                }
            }
            // Microphone
            else {
                activeAudioInput = newInput
            }
        } catch {
            // Re-add the current input if the device change fails.
            session.addInput(currentInput)
        }
    }
    
    // MARK: - Video Format Selection Handling
    func selectFormat(_ format: VideoFormat) {
        guard let device = activeVideoInput?.device,
              let newFormat = device.formats.first(where: { $0.formatName == format.name }) else { return }
        do {
            try device.lockForConfiguration()
            device.activeFormat = newFormat
            device.unlockForConfiguration()
        } catch {
            print("Error setting format")
        }
    }
    
    private func updateVideoFormats(for captureDevice: AVCaptureDevice) {
        videoFormats = captureDevice.formats.compactMap { format in
            VideoFormat(id: format.formatName, name: format.formatName)
        }
        selectedVideoFormat = videoFormats.first(where: { $0.name == captureDevice.activeFormat.formatName }) ?? VideoFormat.invalid
        isCenterStageSupported = captureDevice.activeFormat.isCenterStageSupported
    }
    
    private var observation: NSKeyValueObservation?
    
    private func updateVideoEffectsState(for captureDevice: AVCaptureDevice) {
        // If the format doesn't support an effect, disable the effect's state in the UI
        let format = captureDevice.activeFormat
        isCenterStageSupported = format.isCenterStageSupported
        isPortraitEffectSupported = format.isPortraitEffectSupported
        isStudioLightSupported = format.isStudioLightSupported
        
        isCenterStageEnabled = AVCaptureDevice.isCenterStageEnabled
        isPortraitEffectEnabled = AVCaptureDevice.isPortraitEffectEnabled
        isStudioLightEnabled = AVCaptureDevice.isStudioLightEnabled
    }
}

// MARK: - Supporting Types
/// A representation of capture device to display in the UI.
struct Device: Hashable, Identifiable {
    static let invalid = Device(id: "-1", name: "No camera available")
    let id: String
    let name: String
    // Use the unique id alone for comparisons.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// A representation of video format to display in the UI.
struct VideoFormat: Hashable, Identifiable {
    static let invalid = VideoFormat(id: "-1", name: "invalid")
    let id: String
    let name: String
}

/// Adds a formatName property that generates a name by inspecting the format description.
extension AVCaptureDevice.Format {
    var formatName: String {
        let size = formatDescription.dimensions
        guard let formatName = formatDescription.extensions[.formatName]?.propertyListRepresentation as? String else {
            return "Unnamed \(size.width) x \(size.height)"
        }
        return "\(formatName), \(size.width) x \(size.height)"
    }
}
