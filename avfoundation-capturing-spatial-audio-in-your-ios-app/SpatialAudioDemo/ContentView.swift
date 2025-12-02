/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface.
*/

import AVFoundation
import Combine
import SwiftUI

struct ContentView: View {
    // The audio recorder object.
    @State private var audioRecorder = AudioRecorder()
    
    // CMTime object that tracks time elapsed since began recording.
    @State private var timeElapsed: TimeInterval = 0
    
    // The timer object.
    @State private var timer: Timer?
    
    // A Boolean that indicates whether to display the audio player user interface.
    @State private var showAudioPlayer = false
    
    // A environment value to indicate scene phase changes.
    @Environment(\.scenePhase) var scenePhase
    
    // The main UI view.
    var body: some View {
        VStack {
            if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
                 Text("You haven't authorized Spatial Audio Demo to use the microphone. Change these settings in Settings -> Privacy & Security.")
                 Image(systemName: "lock.trianglebadge.exclamationmark.fill")
                     .resizable()
                     .symbolRenderingMode(.multicolor)
                     .aspectRatio(contentMode: .fit)
            } else {
                if !audioRecorder.isRecording {
                    Text("Tap To Start Recording")
                        .font(.system(size: 34, weight: .light, design: .default))
                }
                if audioRecorder.isRecording {
                    Text("Recording")
                    // Text label for time recording duration.
                    Text(formatTime(timeElapsed))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                    // Waveform UI for the audio recording.
                    LiveWaveformShape(amplitudes: audioRecorder.amplitudes)
                               .stroke(Color.red, lineWidth: 2)
                               .background(Color.clear)
                               .frame(height: 200)
                               .animation(.linear(duration: 0.05), value: audioRecorder.amplitudes)
                }
                    VStack {
                        // UI button to start and stop recording.
                        Button {
                            if audioRecorder.isRecording {
                                Task {
                                    await audioRecorder.stopRecording()
                                    audioRecorder.amplitudes.removeAll()
                                    stopTimer()
                                    showAudioPlayer = true
                                }
                            } else {
                                audioRecorder.amplitudes.removeAll()
                                audioRecorder.currentLevel = 0
                                audioRecorder.startRecording()
                                startTimer()
                                showAudioPlayer = false
                            }
                        } label: {
                            Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                                .padding()
                                .background(Circle().fill(Color.gray.opacity(0.2)))
                        }
                        .padding()
                    }
                }
        }
        .onAppear() {
            audioRecorder.setupCaptureSession()
        }
        .padding()
        .sheet(isPresented: $showAudioPlayer) {
            if !audioRecorder.isRecording && audioRecorder.fileURL != nil {
                if let fileURL = audioRecorder.fileURL {
                    AudioPlayerView(audioURL: fileURL)
                }
            }
        }
    }
    
    // The function to start the timer during recording.
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
        }
    }

    // The function to stop the time after the recording has finished.
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timeElapsed = 0
    }

    // The function to format the time to a string.
    func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct LiveWaveformShape: Shape {
    var amplitudes: [Float]

    /*
     A function that defines a custom Shape for use in SwiftUI.
     It visually represents a waveform, typically from audio data, by drawing vertical lines based on amplitude values.
     This produces a series of vertical lines, spaced evenly along the x-axis, with their heights determined by the amplitude.
     This creates a waveform visualization that updates in real time if amplitudes changes.
     */
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.height / 2
        let widthPerSample = rect.width / CGFloat(amplitudes.count)

        for (index, amp) in amplitudes.enumerated() {
            let xValue = CGFloat(index) * widthPerSample
            let height = CGFloat(amp) * rect.height / 2
            path.move(to: CGPoint(x: xValue, y: midY - height))
            path.addLine(to: CGPoint(x: xValue, y: midY + height))
        }

        return path
    }
}
