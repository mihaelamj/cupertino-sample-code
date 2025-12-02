/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages audio capture and playback.
*/

import Foundation
import AVFAudio


/// Tests the audio engine by recording audio while optionally playing audio in the background.
///
/// For more information, see [What's New in AVAudioEngine](https://developer.apple.com/videos/play/wwdc2019/510).
/// - Tag: AudioCapturer
class AudioCapturer: NSObject, ObservableObject {

    struct AudioNode {
        var player: AVAudioPlayerNode
        var pcmBuffer: AVAudioPCMBuffer
    }

    struct AudioError: Error {
        var description: String
    }

    private let avAudioEngine = AVAudioEngine()

    private let avAudioSession = AVAudioSession.sharedInstance()

    // MARK: Playback

    @Published private(set) var playingBackgroundNoise = false

    @Published private(set) var canPlayRecordedAudio = false

    @Published private(set) var isPlayingRecordedAudio = false

    private var effectsPlaybackNode: AudioNode?

    private var recordedPlaybackNode: AudioNode?

    // MARK: Recording

    @Published private(set) var isVoiceProcessingBypassed = false

    @Published private(set) var captureState: CaptureState?

    /// The location of the recorded audio file.
    private var recordedFileURL: URL

    // MARK: Lifecycle

    override init() {
        self.recordedFileURL = URL(fileURLWithPath: "recording.caf", isDirectory: false, relativeTo: URL(fileURLWithPath: NSTemporaryDirectory()))

        super.init()

        registerForInputAvailabilityUpdates(on: avAudioSession)

        if avAudioSession.isInputAvailable {
            setupAndStartAudioSession()
        }
    }

    deinit {
        unregisterInputAvailabilityUpdates(on: avAudioSession)

        do {
            try avAudioSession.setActive(false)
        } catch let error {
            print("Audio capturer failed to deactivate the audio session: \(String(describing: error))")
        }
    }

    /// Connects to a continuity device's microphone and configures it to receive
    /// audio for 2-way voice communication session.
    /// - Tag: setupAndStartAudioSession
    func setupAndStartAudioSession() {
        configureAudioOutput()
        enableVoiceProcessing(true)
        configureAudioSessionForVoiceChat()
        startAudioEngine()
    }

    /// Configures the audio engine to produce audio for the first output node.
    func configureAudioOutput() {
        let mainMixer = avAudioEngine.mainMixerNode
        let output = avAudioEngine.outputNode

        // Generates a format for the first audio node's bus.
        let format = avAudioEngine.outputNode.outputFormat(forBus: .zero)
        avAudioEngine.connect(mainMixer, to: output, format: format)
    }

    /// Configures the audio engine applies voice processing settings and prints
    /// the result, or error, to the console.
    /// - Parameter enabled: A Boolean value that indicates whether the audio
    /// engine applies voice processing to the its input audio data.
    /// processing
    func enableVoiceProcessing(_ enabled: Bool) {
        let result: Void?
        result = try? avAudioEngine.inputNode.setVoiceProcessingEnabled(enabled)

        guard result != nil else {
            print("Audio engine unable to configure voice processing.")
            return
        }

        print("Voice processing: \(enabled ? "ON" : "OFF")")
    }

    /// Configures and activates the audio session.
    /// - Tag: configureAudioSessionForVoiceChat
    private func configureAudioSessionForVoiceChat() {

        do {
            try avAudioSession.setCategory(.playAndRecord,
                                           mode: .voiceChat,
                                           options: [])
        } catch let error {
            var message = "Unable to set the audio session's category / mode: "
            message += String(describing: error)
            print(message)
        }

        do {
            try avAudioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch let error {
            var message = "Unable to activate audio session: "
            message += String(describing: error)
            print(message)
        }
    }

    /// Prepares and starts the audio engine and handles any errors.
    public func startAudioEngine() {
        avAudioEngine.prepare()
        do {
            try avAudioEngine.start()
            print("Audio engine: ON")
        } catch let error {
            print("Audio enginer failed to start: \(String(describing: error))")
        }
    }

    public func stopAudioEngine() {
        avAudioEngine.stop()
    }

    // MARK: Voice Processing

    /// Temporarily disables voice processing on the audio engine's input node.
    ///
    /// - Tag: bypassVoiceProcessing
    public func bypassVoiceProcessing(_ bypass: Bool) {
        // If true, temporarily disables echo cancelation.
        avAudioEngine.inputNode.isVoiceProcessingBypassed = bypass

        DispatchQueue.main.async {
            self.isVoiceProcessingBypassed = bypass
        }

        var message = "Audio engine's voice processing: "
        message += bypass ? "bypassed" : "normal"
        print(message)
    }

    // MARK: Recording

    /// Returns a Boolean that indicates whether a person gives the app permission
    /// to record video from the camera.
    ///
    /// The system shows a prompt if `.recordPermission` is `.undetermined`.
    private func getRecordingPermission() async -> Bool {
        if AVAudioApplication.shared.recordPermission == .granted {
            return true
        } else {
            return await AVAudioApplication.requestRecordPermission()
        }
    }

    /// Starts an audio recording by installing a tap on the audio engine's input node.
    ///
    /// Writes the received audio buffers to an `AVAudioFile`.
    public func startRecording() async {
        do {
            // Checks recording permissions.
            guard await getRecordingPermission() else {
                throw AudioError(description: "Audio capturer permission denied.")
            }

            // Retrieves and verifies the audio input format.
            let voiceIOFormat = avAudioEngine.inputNode.inputFormat(forBus: .zero)
            guard voiceIOFormat.sampleRate > 0, voiceIOFormat.channelCount > 0 else {
                throw AudioError(description: "Audio engine input format isn't valid.")
            }

            // Deletes the previous recording (if it exists) and creates a new one.
            try? FileManager.default.removeItem(at: recordedFileURL)
            let file = try AVAudioFile(forWriting: recordedFileURL, settings: voiceIOFormat.settings)

            // Starts writing audio buffers to the file.
            print("Audio capture: starting")
            avAudioEngine.inputNode.installTap(onBus: .zero, bufferSize: 4800, format: voiceIOFormat) { (buffer, time) -> Void in
                do {
                    try file.write(from: buffer)
                    print("Audio tap wrote \(buffer.frameCapacity) frames.")
                } catch let error {
                    print("Audio tap failed to write buffer: \(String(describing: error))")
                }
            }

            DispatchQueue.main.async {
                self.captureState = .recording(startTime: .now)
                self.canPlayRecordedAudio = false
            }
        } catch let error {
            print("Audio capturer failed to start audio capture: \(String(describing: error))")
            DispatchQueue.main.async {
                self.captureState = .failed(reason: String(describing: error))
            }
        }
    }

    /// Stops the audio recording by removing the tap on the audio engine's input node.
    public func stopRecording() {
        print("Audio capture: stopping")
        avAudioEngine.inputNode.removeTap(onBus: .zero)

        DispatchQueue.main.async {
            self.captureState = nil
            self.canPlayRecordedAudio = true
        }
    }

    // MARK: Audio Playback

    /// Starts playing the recorded audio file.
    public func startRecordedPlayback() {
        do {
            guard let buffer = Self.getBuffer(fileURL: recordedFileURL) else {
                throw AudioError(description: "failed to get recorded audio buffer from \(recordedFileURL.absoluteString)")
            }

            print("Audio capturer starting recorded playback.")
            let playbackNode = try startLoopingAudioBuffer(buffer)

            DispatchQueue.main.async {
                self.recordedPlaybackNode = playbackNode
                self.isPlayingRecordedAudio = true
            }
        } catch let error {
            print("Audio capturer failed to start recorded playback: \(String(describing: error))")
        }
    }

    /// Starts playing an audio file with background effects.
    public func playBackrgoundNoise() {
        do {
            guard let url = Bundle.main.url(forResource: "drumLoop", withExtension: "caf") else {
                throw AudioError(description: "Audio capturer can't find file in bundle.")
            }
            guard let buffer = Self.getBuffer(fileURL: url) else {
                throw AudioError(description: "Audio capturer failed to get buffer for \(url.absoluteString)")
            }

            let playbackNode = try startLoopingAudioBuffer(buffer)

            DispatchQueue.main.async {
                self.effectsPlaybackNode = playbackNode
                self.playingBackgroundNoise = true
                print("Playing background noise.")
            }
        } catch let error {
            print("Audio capturer can't play background noise: \(String(describing: error))")
        }
    }

    /// Stops the recorded audio file from playing.
    public func stopRecordedPlayback() {
        print("Audio capturer stopping recorded playback.")
        if let node = recordedPlaybackNode {
            stopLoopingAudio(for: node)
            recordedPlaybackNode = nil
        }
        DispatchQueue.main.async {
            self.isPlayingRecordedAudio = false
        }
    }

    /// Stops the background effects audio file from playing.
    public func stopBackgroundNoise() {
        print("Stopping background noise.")
        if let node = effectsPlaybackNode {
            stopLoopingAudio(for: node)
            effectsPlaybackNode = nil
        }
        DispatchQueue.main.async {
            self.playingBackgroundNoise = false
        }
    }

    /// A helper function for starting playback of an audio buffer.
    ///
    /// Playback is set to loop indefinitely until stopped.
    private func startLoopingAudioBuffer(_ buffer: AVAudioPCMBuffer) throws -> AudioNode {

        guard avAudioEngine.isRunning else {
            throw AudioError(description: "Audio Engine is not running")
        }

        let player = AVAudioPlayerNode()

        let mainMixer = avAudioEngine.mainMixerNode
        avAudioEngine.attach(player)
        avAudioEngine.connect(player, to: mainMixer, format: buffer.format)

        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()

        return .init(player: player, pcmBuffer: buffer)
    }

    /// Stops and removes an audio playback node.
    private func stopLoopingAudio(for node: AudioNode) {
        node.player.stop()
        avAudioEngine.detach(node.player)
    }
}

// MARK: -

extension AudioCapturer {

    /// Returns an audio data buffer by reading from an audio file.
    /// - Parameter fileURL: A URL to an audio file.
    private static func getBuffer(fileURL: URL) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: fileURL) else {
            print("Audio capturer failed to load file from \(fileURL.absoluteString)")
            return nil
        }

        file.framePosition = 0

        let bufferCapacity = AVAudioFrameCount(file.length) + AVAudioFrameCount(file.processingFormat.sampleRate * 0.1)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: bufferCapacity) else {
            print("Audio capturer failed to initialize AVAudioPCMBuffer from file: \(String(describing: file))")
            return nil
        }

        do {
            try file.read(into: buffer)
        } catch let error {
            print("Audio capturer failed to load file into buffer: \(String(describing: error))")
            return nil
        }

        file.framePosition = 0
        return buffer
    }
}

// MARK: -

extension AudioCapturer {
    private static let inputAvailableKeyPath = "isInputAvailable"

    func registerForInputAvailabilityUpdates(on session: AVAudioSession) {
        session.addObserver(self,
                            forKeyPath: Self.inputAvailableKeyPath,
                            options: [.new],
                            context: nil)
    }

    func unregisterInputAvailabilityUpdates(on session: AVAudioSession) {
        session.removeObserver(self, forKeyPath: Self.inputAvailableKeyPath)
    }

    /// Responds to a change in an audio session's input available property.
    /// - Parameter didBecomeAvailable: The property's new value.
    func processAudioInputAvailabilityChange(_ didBecomeAvailable: Bool) {
        guard didBecomeAvailable else {
            if avAudioEngine.isRunning { stopAudioEngine() }
            return
        }

        if avAudioEngine.isRunning { return }
        setupAndStartAudioSession()
    }

    /// Observes changes to the system's input availability property.
    ///
    /// - Parameters:
    ///   - keyPath: The path to the property that changed.
    ///   - object: The object with the property.
    ///   - change: A dictionary of information about the change.
    ///   - context: Additional context, if applicable.
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {

        guard keyPath == Self.inputAvailableKeyPath else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }

        guard let isAvailable = change?[.newKey] as? Bool else { return }

        processAudioInputAvailabilityChange(isAvailable)
    }
}
