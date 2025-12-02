/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class for handling AVAudioEngine.
*/

import AVFoundation
import Foundation

class AudioEngine {

    private var recordedFileURL = URL(fileURLWithPath: "input.caf", isDirectory: false, relativeTo: URL(fileURLWithPath: NSTemporaryDirectory()))
    private var recordedFilePlayer = AVAudioPlayerNode()
    private var avAudioEngine = AVAudioEngine()
    private var fxPlayer = AVAudioPlayerNode()
    private var fxBuffer: AVAudioPCMBuffer
    private var speechPlayer = AVAudioPlayerNode()
    private var speechBuffer: AVAudioPCMBuffer
    private var isNewRecordingAvailable = false
    private var fileFormat: AVAudioFormat
    private var recordedFile: AVAudioFile?

    public private(set) var voiceIOFormat: AVAudioFormat
    public private(set) var isRecording = false
    public private(set) var speechPowerMeter = PowerMeter()
    public private(set) var fxPowerMeter = PowerMeter()
    public private(set) var voiceIOPowerMeter = PowerMeter()

    enum AudioEngineError: Error {
        case bufferRetrieveError
        case fileFormatError
        case audioFileNotFound
    }

    init() throws {
        avAudioEngine.attach(fxPlayer)
        avAudioEngine.attach(speechPlayer)
        avAudioEngine.attach(recordedFilePlayer)
        print("Record file URL: \(recordedFileURL.absoluteString)")

        guard let speechURL = Bundle.main.url(forResource: "sampleVoice8kHz", withExtension: "wav") else { throw AudioEngineError.audioFileNotFound }
        guard let tempSpeechBuffer = AudioEngine.getBuffer(fileURL: speechURL) else { throw AudioEngineError.bufferRetrieveError }
        speechBuffer = tempSpeechBuffer

        voiceIOFormat = speechBuffer.format

        print("Voice IO format: \(String(describing: voiceIOFormat))")
        guard let tempFileFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: voiceIOFormat.sampleRate,
                                   channels: voiceIOFormat.channelCount,
                                   interleaved: true) else { throw AudioEngineError.fileFormatError }
        fileFormat = tempFileFormat

        guard let fxURL = Bundle.main.url(forResource: "Synth", withExtension: "aif") else { throw AudioEngineError.audioFileNotFound }
        guard let tempFxBuffer = AudioEngine.getBuffer(fileURL: fxURL) else { throw AudioEngineError.bufferRetrieveError }
        fxBuffer = tempFxBuffer

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(configChanged(_:)),
                                               name: .AVAudioEngineConfigurationChange,
                                               object: avAudioEngine)
    }

    @objc
    func configChanged(_ notification: Notification) {
        checkEngineIsRunning()
    }

    private static func getBuffer(fileURL: URL) -> AVAudioPCMBuffer? {
        let file: AVAudioFile!
        do {
            try file = AVAudioFile(forReading: fileURL)
        } catch {
            print("Could not load file: \(error)")
            return nil
        }
        file.framePosition = 0
        
        // Add 100 ms to the capacity.
        let bufferCapacity = AVAudioFrameCount(file.length)
                + AVAudioFrameCount(file.processingFormat.sampleRate * 0.1)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: bufferCapacity) else { return nil }
        do {
            try file.read(into: buffer)
        } catch {
            print("Could not load file into buffer: \(error)")
            return nil
        }
        file.framePosition = 0
        return buffer
    }

    func setup() {
        let input = avAudioEngine.inputNode
        do {
            try input.setVoiceProcessingEnabled(true)
        } catch {
            print("Could not enable voice processing \(error)")
            return
        }

        let output = avAudioEngine.outputNode
        let mainMixer = avAudioEngine.mainMixerNode

        avAudioEngine.connect(fxPlayer, to: mainMixer, format: fxBuffer.format)
        avAudioEngine.connect(speechPlayer, to: mainMixer, format: speechBuffer.format)
        avAudioEngine.connect(recordedFilePlayer, to: mainMixer, format: voiceIOFormat)
        avAudioEngine.connect(mainMixer, to: output, format: voiceIOFormat)

        input.installTap(onBus: 0, bufferSize: 256, format: voiceIOFormat) { buffer, when in
            if self.isRecording {
                do {
                    try self.recordedFile?.write(from: buffer)
                } catch {
                    print("Could not write buffer: \(error)")
                }
                self.voiceIOPowerMeter.process(buffer: buffer)
            } else {
                self.voiceIOPowerMeter.processSilence()
            }
        }

        speechPlayer.installTap(onBus: 0, bufferSize: 256, format: nil) { buffer, _ in
            if self.speechPlayer.isPlaying {
                // Update the speech meter.
                self.speechPowerMeter.process(buffer: buffer)
            } else {
                self.speechPowerMeter.processSilence()
            }
        }

        fxPlayer.installTap(onBus: 0, bufferSize: 256, format: nil) { buffer, _ in
            if self.fxPlayer.isPlaying {
                // Update the effects meter.
                self.fxPowerMeter.process(buffer: buffer)
            } else {
                self.fxPowerMeter.processSilence()
            }
        }

        avAudioEngine.prepare()
    }

    func start() {
        do {
            try avAudioEngine.start()
        } catch {
            print("Could not start audio engine: \(error)")
        }
    }

    func checkEngineIsRunning() {
        if !avAudioEngine.isRunning {
            start()
        }
    }

    func fxPlayerPlay(_ shouldPlay: Bool) {
        if shouldPlay {
            fxPlayer.scheduleBuffer(fxBuffer, at: nil, options: .loops)
            fxPlayer.play()
        } else {
            fxPlayer.stop()
        }
    }

    func speechPlayerPlay(_ shouldPlay: Bool) {
        if shouldPlay {
            speechPlayer.scheduleBuffer(speechBuffer, at: nil, options: .loops)
            speechPlayer.play()
        } else {
            speechPlayer.stop()
        }
    }

    func bypassVoiceProcessing(_ bypass: Bool) {
        let input = avAudioEngine.inputNode
        input.isVoiceProcessingBypassed = bypass
    }

    func toggleRecording() {
        if isRecording {
            isRecording = false
            recordedFile = nil // Close the file.
        } else {
            recordedFilePlayer.stop()

            do {
                recordedFile = try AVAudioFile(forWriting: recordedFileURL, settings: fileFormat.settings)
                isNewRecordingAvailable = true
                isRecording = true
            } catch {
                print("Could not create file for recording: \(error)")
            }
        }
    }

    func stopRecordingAndPlayers() {
        if isRecording {
            isRecording = false
        }

        recordedFilePlayer.stop()
        fxPlayer.stop()
        speechPlayer.stop()
    }

    var isPlaying: Bool {
        return recordedFilePlayer.isPlaying
    }

    func togglePlaying() {
        if recordedFilePlayer.isPlaying {
            recordedFilePlayer.pause()
        } else {
            if isNewRecordingAvailable {
                guard let recordedBuffer = AudioEngine.getBuffer(fileURL: recordedFileURL) else { return }
                recordedFilePlayer.scheduleBuffer(recordedBuffer, at: nil, options: .loops)
                isNewRecordingAvailable = false
            }
            recordedFilePlayer.play()

            fxPlayer.stop()
            speechPlayer.stop()
        }
    }
}
