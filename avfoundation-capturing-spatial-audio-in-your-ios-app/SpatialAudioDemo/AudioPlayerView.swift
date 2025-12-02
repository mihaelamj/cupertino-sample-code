/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides an audio playback user interface.
*/

import SwiftUI

/*
A user interface component, called `AudioPlayerView`, which provides a simple audio playback UI with the following features:
 - Play and Pause buttons.
 - A slider to seek within the audio.
 - Buttons that allow people to rewind or fast forward in five-second intervals.
 - A time label, showing the current time and total duration.
*/

struct AudioPlayerView: View {
    @State private var viewModel = AudioPlayerViewModel()
    let audioURL: URL

    var body: some View {
        VStack(spacing: 20) {
            // Slider which shows the duration of the audio file being played.
            Slider(value: $viewModel.currentTime,
                   in: 0...viewModel.duration,
                   onEditingChanged: { editing in
                       if !editing {
                           viewModel.seek(to: viewModel.currentTime)
                       }
                   })
            // Text label to display the current position in the audio file, as well as its duration.
            Text("\(formatTime(viewModel.currentTime)) / \(formatTime(viewModel.duration))")
                .font(.caption)
                .monospacedDigit()
            // Button to rewind the audio by 5 seconds.
            HStack {
                Button {
                    viewModel.rewindAudioFiveSeconds()
                } label: {
                    Image(systemName: "5.arrow.trianglehead.counterclockwise")
                    .font(.system(size: 25))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                // Button to play and pause the audio file with the `AVPlayer`.
                Button {
                    if viewModel.isPlaying && viewModel.currentTime != viewModel.duration {
                        viewModel.pause()
                    } else {
                        if !viewModel.isPlaying {
                            viewModel.loadAudio(from: audioURL)
                            if viewModel.currentTime == viewModel.duration {
                                viewModel.seekToAndPlay(to: 0)
                            } else {
                                viewModel.seekToAndPlay(to: viewModel.currentTime)
                            }
                        } else {
                            if viewModel.currentTime != viewModel.duration {
                                viewModel.seekToAndPlay(to: viewModel.currentTime)
                            } else {
                                viewModel.seekToAndPlay(to: 0)
                            }
                        }
                    }
                } label: {
                    if viewModel.isPlaying && viewModel.currentTime != viewModel.duration {
                        Image(systemName: ( "pause.fill"))
                            .font(.system(size: 35))
                            .foregroundColor(.blue)
                            .padding()
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                    } else {
                        Image(systemName: ( "play.fill"))
                            .font(.system(size: 35))
                            .foregroundColor(.blue)
                            .padding()
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                    }
                }
                // Button to fast forward the audio by five seconds.
                Button(action: {
                    viewModel.skipAudioFiveSeconds()
                }) {
                    Image(systemName: "5.arrow.trianglehead.clockwise")
                        .font(.system(size: 25))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
            }
        }
        .padding()
    }

    // Function to format time.
    func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
