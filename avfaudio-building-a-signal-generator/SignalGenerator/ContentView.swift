/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view that presents a user interface and manages interaction with the audio manager.
*/

import SwiftUI

struct ContentView: View {
    // The audio manager that is bound to this view.
    @Binding var audioManager: AudioManager
    
    var body: some View {
        VStack {
            Text("Waveform")
            Picker("Waveform", selection: $audioManager.waveform) {
                ForEach(Waveform.allCases, id: \.rawValue) { waveform in
                    Text(waveform.description)
                        .tag(waveform)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            Text("Frequency: \(audioManager.frequency, specifier: "%.1f") Hz")
                .padding(.top)
                .opacity(audioManager.waveform == .noise ? 0 : 1)
            Slider(value: $audioManager.frequency,
                   in: 20...6000,
                   onEditingChanged: { _ in },
                   minimumValueLabel: Text("20"),
                   maximumValueLabel: Text("6000")) {
            }
                .opacity(audioManager.waveform == .noise ? 0 : 1)
            Text("Amplitude: \(audioManager.amplitude, specifier: "%.1f") dB")
            Slider(value: $audioManager.amplitude,
                   in: -48...0,
                   onEditingChanged: { _ in },
                   minimumValueLabel: Text("-48"),
                   maximumValueLabel: Text("0")) {
            }
                .padding(.bottom)
            HStack {
                Button("Start") {
                    audioManager.start()
                }
                Button("Stop") {
                    audioManager.stop()
                }
            }
        }
        .padding()
    }
}

extension Waveform: CaseIterable {
    public static var allCases: [Waveform] = [.sine, .sawtooth, .square, .triangle, .noise]
}

extension Waveform: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sine:
            "Sine"
        case .sawtooth:
            "Sawtooth"
        case .square:
            "Square"
        case .triangle:
            "Triangle"
        case .noise:
            "Noise"
        @unknown default:
            "Unknown waveform"
        }
    }
}
