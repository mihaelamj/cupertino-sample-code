/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The audio manager that connects a signal generator to an audio engine and maintains the state of the content view.
*/

import AVFoundation

@Observable class AudioManager {
    private let signalGenerator = SignalGenerator()
    private var engine = AVAudioEngine()
    
    var waveform: Waveform = .sine {
        willSet {
            signalGenerator.setWaveform(newValue)
        }
    }
    
    var frequency: Float = 440.0 {
        willSet {
            signalGenerator.setFrequency(newValue)
        }
    }
    
    var amplitude: Float = -12.0 {
        willSet {
            signalGenerator.setAmplitude(newValue)
        }
    }
    
    init() {
        let srcNode = AVAudioSourceNode(renderBlock: signalGenerator.renderBlock)
        let mainMixer = engine.mainMixerNode
        let output = engine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let inputFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                        sampleRate: outputFormat.sampleRate,
                                        channels: 1,
                                        interleaved: outputFormat.isInterleaved)
        signalGenerator.setSampleRate(outputFormat.sampleRate)
        engine.attach(srcNode)
        engine.connect(srcNode, to: mainMixer, format: inputFormat)
        engine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 0.5
    }
    
    func start() {
        do {
            try engine.start()
        } catch {
            print("Could not start engine: \(error)")
        }
    }
    
    func stop() {
        engine.stop()
    }
}
