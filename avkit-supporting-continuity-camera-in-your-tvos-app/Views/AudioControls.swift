/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view with buttons for controlling audio options and playback.
*/

import SwiftUI

/// A set of controls for starting and stopping audio recording via the audio engine.
struct AudioControls: View {

    @ObservedObject var audioCapturer: AudioCapturer

    private var voiceProcessingBinding: Binding<Bool> {
        return .init {
            return audioCapturer.isVoiceProcessingBypassed
        } set: {
            audioCapturer.bypassVoiceProcessing($0)
        }
    }

    var body: some View {
        VStack {
            LabeledContent("Recording Playback") {
                if audioCapturer.isPlayingRecordedAudio {
                    stopRecordedPlaybackButton
                } else {
                    startRecordedPlaybackButton
                        .disabled(!audioCapturer.canPlayRecordedAudio)
                }
            }
            LabeledContent("Backrgound Noise") {
                if audioCapturer.playingBackgroundNoise {
                    stopBackgroundNoiseButton
                } else {
                    startBackgroundNoiseButton
                }
            }
            Toggle("Bypass Voice Processing", isOn: voiceProcessingBinding)
        }
        .buttonStyle(.bordered)
    }

    // MARK: Recording Playback Buttons

    private var startRecordedPlaybackButton: some View {
        Button {
            audioCapturer.startRecordedPlayback()
        } label: {
            Image(systemName: "play.fill")
        }
    }

    private var stopRecordedPlaybackButton: some View {
        Button {
            audioCapturer.stopRecordedPlayback()
        } label: {
            Image(systemName: "stop.fill")
        }
    }

    // MARK: Effects Playback Buttons

    private var startBackgroundNoiseButton: some View {
        Button {
            audioCapturer.playBackrgoundNoise()
        } label: {
            Image(systemName: "play.fill")
        }
    }

    private var stopBackgroundNoiseButton: some View {
        Button {
            audioCapturer.stopBackgroundNoise()
        } label: {
            Image(systemName: "stop.fill")
        }
    }
}
