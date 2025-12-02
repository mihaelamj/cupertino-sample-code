/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view used for Cinematic mode video playback.
*/

import SwiftUI
import AVKit

struct CinematicPlayer: View {

    let player: AVPlayer?

    @Binding var fNumber: Float

    @State private var showDetections = false

    @State private var playerRefershing = false

    var body: some View {
        VStack {

            VideoPlayer(player: player)
                .disabled(playerRefershing)

            VStack(alignment: .leading) {
                Slider(value: $fNumber, in: 2...16) {
                    Text("Aperture")
                } minimumValueLabel: {
                    Label("Open", systemImage: "camera.aperture")
                } maximumValueLabel: {
                    Label("Close", systemImage: "camera.aperture")
                } onEditingChanged: { editing in
                    if !editing {
                        refreshPlayer(fNumber: fNumber, editMode: showDetections)
                    }
                }
                .labelsHidden()
                .disabled(playerRefershing)

                Toggle(isOn: $showDetections) {
                    Text("Show Detections")
                }
                .disabled(playerRefershing)
            }.padding()

        }
        .onAppear {
            // Force the player to re-render the current frame with the new editing mode.
            refreshPlayer(fNumber: fNumber, editMode: showDetections)
        }
        .onChange(of: showDetections) { _, _ in
            // Refresh the player with show detections.
            refreshPlayer(fNumber: fNumber, editMode: showDetections)
        }
        .onChange(of: player) { _, _ in
            refreshPlayer(fNumber: fNumber, editMode: showDetections)
        }
        .onDisappear() {
            player?.pause()
        }
    }

    private func refreshPlayer(fNumber: Float, editMode: Bool) {
        if playerRefershing {
            return
        }

        guard let player else { return }

        playerRefershing = true
        if player.timeControlStatus == .playing {
            player.pause()
        }
        Task { @MainActor in
            await refreshFrame(fNumber: fNumber, editMode: editMode)
            playerRefershing = false
        }
    }

    // Set up the video composition for refresh.
    private func setVideoComposition(fNumber: Float, editMode: Bool) {
        guard let player = self.player else { return }
        guard let playerItem = player.currentItem else { return }
        guard let videoComposition = playerItem.videoComposition else { return }
        guard let instructions: [SampleCompositionInstruction] =
                videoComposition.instructions as? [SampleCompositionInstruction] else {
            fatalError("Unexpected instructions type")
        }
        let oldInstruction = instructions[0]
        let compositionInfo = oldInstruction.compositionInfo
        let instruction = SampleCompositionInstruction(
            renderingSession: oldInstruction.renderingSession,
            compositionInfo: compositionInfo,
            script: oldInstruction.script,
            fNumber: fNumber,
            editMode: editMode)
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.sourceTrackIDForFrameTiming = videoComposition.sourceTrackIDForFrameTiming
        mutableVideoComposition.sourceSampleDataTrackIDs = videoComposition.sourceSampleDataTrackIDs
        mutableVideoComposition.customVideoCompositorClass = SampleCustomCompositor.self
        mutableVideoComposition.instructions = [instruction]
        mutableVideoComposition.frameDuration = videoComposition.frameDuration
        mutableVideoComposition.renderSize = videoComposition.renderSize
        playerItem.videoComposition = mutableVideoComposition
    }

    // Refresh the frame for a change in instructions.
    private func refreshFrame(fNumber: Float, editMode: Bool) async {
        guard let player = self.player else { return }
        player.pause()
        guard let playerItem = player.currentItem else { return }
        setVideoComposition(fNumber: fNumber, editMode: editMode)

        let seekingWaits = playerItem.seekingWaitsForVideoCompositionRendering

        let frameTime = player.currentTime()

        switch player.timeControlStatus {
        case .paused, .playing:
            playerItem.seekingWaitsForVideoCompositionRendering = true
            await player.seek(to: frameTime, toleranceBefore: .zero, toleranceAfter: .zero)
            playerItem.seekingWaitsForVideoCompositionRendering = seekingWaits
        case .waitingToPlayAtSpecifiedRate:
            break
        @unknown default:
            break
        }
    }
}
