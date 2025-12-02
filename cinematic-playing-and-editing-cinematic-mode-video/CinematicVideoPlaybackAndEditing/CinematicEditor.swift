/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view used for Cinematic mode video editing.
*/

import SwiftUI
import CoreMedia
import Cinematic
import Photos

struct CinematicEditor: View {

    @Binding var asset: CinematicAsset

    @State private var imageFetch = false

    @State private var focusChangeInProgress = false

    @State private var objectTrackingInProgress = false

    @Binding var exportOrSaveScriptInProgress: Bool

    @State private var videoRect = CGRect.zero

    var body: some View {

        VStack {
            player
            controls
        }

        .onAppear {
            let script = asset.cinematicAssetData.script
            asset.editTimelinePosition = asset.player.currentTime().seconds / script.timeRange.end.seconds

            updateEditImage(time: getEditScriptFrameTime())
        }
    }
    
    private var player: some View {
        ZStack {
            PlayerLayerContainer(player: asset.player, videoRect: $videoRect)
                .overlay {
                    GeometryReader { geometry in
                        let space = CoordinateSpace.local
                        
                        Color.black.opacity(0.000_01)
                            .onTapGesture(count: 2, coordinateSpace: space) { point in
                                // Strong decision, double tap.
                                onFocusChange(
                                    point: normalizePoint(point: point),
                                    strongDecision: true)
                            }
                            .onTapGesture(count: 1, coordinateSpace: space) { point in
                                // Weak decision, single tap.
                                onFocusChange(
                                    point: normalizePoint(point: point),
                                    strongDecision: false)
                            }
                    }
                }
            ProgressView().opacity(objectTrackingInProgress ? 1: 0)
        }
    }
    
    private var controls: some View {
        VStack(alignment: .leading) {
            Slider(value: $asset.fNumber, in: 2...16) {
                Text("Aperture")
            } minimumValueLabel: {
                Label("Open", systemImage: "camera.aperture")
            } maximumValueLabel: {
                Label("Close", systemImage: "camera.aperture")
            } onEditingChanged: { editing in
                if !editing {
                    updateEditImage(time: asset.currentEditTime)
                }
            }
            .labelsHidden()
            .disabled(imageFetch)

            Slider(value: $asset.editTimelinePosition, in: 0...1) {
                Text("Timeline")
            } minimumValueLabel: {
                Image(systemName: "calendar.day.timeline.left")
            } maximumValueLabel: {
                Image(systemName: "calendar.day.timeline.right")
            } onEditingChanged: { editing in
                if !editing {
                    updateEditImage(time: getEditScriptFrameTime())
                }
            }
            .labelsHidden()
            .disabled(imageFetch)

            HStack {
                Button("Save Script") {
                    exportOrSaveScriptInProgress = true
                    saveScript()
                    exportOrSaveScriptInProgress = false
                }
                .buttonStyle(.bordered)
                .disabled(exportOrSaveScriptInProgress)

                Button("Export") {
                    exportOrSaveScriptInProgress = true
                    Task {
                        await export()
                        exportOrSaveScriptInProgress = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(exportOrSaveScriptInProgress)
            }
        }.padding()
    }
}

extension CinematicEditor {
    private func onFocusChange(point: CGPoint, strongDecision: Bool) {
        if focusChangeInProgress {
            return
        }
        focusChangeInProgress = true
        Task {
            await changeFocus(point: point, strongDecision: strongDecision)
            updateEditImage(time: asset.currentEditTime)
            focusChangeInProgress = false
        }
    }

    // Apply a reverse transform to get normalized coordinates in the natural size.
    func applyReverseTransform(point: CGPoint) -> CGPoint {
        let preferredTransform = asset.cinematicAssetData.renderingSession.preferredTransform
        let inverseTransform = CGAffineTransformInvert(preferredTransform)
        let naturalSize = asset.cinematicAssetData.assetInfo.naturalSize
        let preferredSize = asset.cinematicAssetData.assetInfo.preferredSize
        let texturePoint = CGPoint(x: point.x * preferredSize.width,
                                   y: point.y * preferredSize.height)
        let textureRect = CGRect(origin: texturePoint, size: CGSize(width: 1, height: 1))
        let transformedRect = CGRectApplyAffineTransform(textureRect, inverseTransform)
        let finalPoint = CGPoint(x: transformedRect.origin.x / naturalSize.width,
                                 y: transformedRect.origin.y / naturalSize.height)
        return finalPoint
    }

    private func changeFocus(point: CGPoint, strongDecision: Bool) async {

        let finalPoint = applyReverseTransform(point: point)
        let cinematicAssetData = asset.cinematicAssetData

        let cinematicScript = cinematicAssetData.script

        let nominalFrameRate = cinematicAssetData.nominalFrameRate
        let naturalTimeScale = cinematicAssetData.naturalTimeScale

        let tolerance = CMTimeMakeWithSeconds(1.0 / Double(nominalFrameRate), preferredTimescale: naturalTimeScale)

        if let cinematicScriptFrame = cinematicScript.frame(at: asset.currentEditTime, tolerance: tolerance) {
            let allDetections = cinematicScriptFrame.allDetections
            var detections: [CNDetection] = []
            // Go over all the detections to find the detection that contains the point of interest.
            for detection in allDetections {
                let rect = detection.normalizedRect
                if rect.contains(finalPoint) {
                    // Human face is the preference for this sample app.
                    if detection.detectionType == .humanFace {
                        detections.insert(detection, at: 0)
                        break
                    } else {
                        detections.append(detection)
                    }
                }
            }
            // Add a user decision if there is already existing detection.
            if !detections.isEmpty {
                if let detectionID = detections[0].detectionID {
                    let decision = CNDecision(time: cinematicScriptFrame.time,
                                              detectionID: detectionID,
                                              strong: strongDecision)
                    _ = cinematicScript.addUserDecision(decision)
                    return
                }
            }

            // Object tracking.
            let timeRange = CMTimeRange(start: cinematicScriptFrame.time, end: cinematicScript.timeRange.end)

            objectTrackingInProgress = true
            let objectTracking = SampleObjectTracking(commandQueue: cinematicAssetData.commandQueue)
            await objectTracking.handleObjectTracking(
                cinematicAssetData: cinematicAssetData,
                pointOfInterest: finalPoint,
                timeRange: timeRange,
                strongDecision: strongDecision)
            objectTrackingInProgress = false
        }
    }

    private func saveScript() {

        let script = asset.cinematicAssetData.script
        asset.cinematicAssetData.script.fNumber = asset.fNumber

        // Get and write script changes to the application support directory.
        let changes = script.changes()

        do {

            let applicationSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask, appropriateFor: nil, create: true)
            let url = applicationSupport.appendingPathComponent(asset.pathComponent, conformingTo: .archive)

            try changes.dataRepresentation.write(to: url)
        } catch {
            fatalError("Failed to save CN Script")
        }
    }

    // Export the video using video composition.
    private func export() async {
        guard let playerItem = asset.player.currentItem else { return }

        let playerItemAsset = playerItem.asset
        
        guard let avComposition = playerItemAsset as? AVComposition else { fatalError("Unexpected asset type")
        }

        let presetName = AVAssetExportPresetHighestQuality
        guard await AVAssetExportSession.compatibility(ofExportPreset: presetName,
                                                       with: avComposition,
                                                       outputFileType: nil) else {
            fatalError("Export session not compatible")
        }

        guard let avExportSession = AVAssetExportSession(asset: avComposition,
                                                         presetName: presetName) else {
            fatalError("Unable to create AVAssetExportSession.")
        }

        let temp = FileManager.default.temporaryDirectory
        let fileURL = temp.appendingPathComponent(UUID().uuidString, conformingTo: .quickTimeMovie)

        avExportSession.videoComposition = getVideoComposition(editMode: false)
        avExportSession.outputURL = fileURL
        avExportSession.outputFileType = .mov
        avExportSession.metadataItemFilter = AVMetadataItemFilter.forSharing()

        await avExportSession.export()

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    // Get the updated edit image.
    private func updateEditImage(time: CMTime) {
        if imageFetch {
            return
        }
        imageFetch = true
        asset.currentEditTime = time

        Task { @MainActor in
            await refreshFrame(time: asset.currentEditTime)
            imageFetch = false
        }
        return
    }
    
    // Set up video composition for refresh.
    private func getVideoComposition(editMode: Bool = true) -> AVVideoComposition? {
        let player = asset.player
        guard let playerItem = player.currentItem else { return nil }
        guard let videoComposition = playerItem.videoComposition else { return nil }
        guard let instructions: [SampleCompositionInstruction] =
                videoComposition.instructions as? [SampleCompositionInstruction] else {
            fatalError("Unexpected instructions type")
        }
        let oldInstruction = instructions[0]
        let fNumber = asset.fNumber
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
        return mutableVideoComposition
    }

    // Refresh the frame for a change in instructions.
    private func refreshFrame(time: CMTime) async {
        let player = asset.player
        player.pause()
        guard let playerItem = player.currentItem else { return }
        playerItem.videoComposition = getVideoComposition()

        let seekingWaits = playerItem.seekingWaitsForVideoCompositionRendering

        switch player.timeControlStatus {
        case .paused, .playing:
            playerItem.seekingWaitsForVideoCompositionRendering = true
            await player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            playerItem.seekingWaitsForVideoCompositionRendering = seekingWaits
        case .waitingToPlayAtSpecifiedRate:
            break
        @unknown default:
            break
        }
    }

    private func normalizePoint(point: CGPoint) -> CGPoint {
        // Normalize the point.
        let normalizedPoint = CGPoint(
            x: (point.x - videoRect.origin.x) / videoRect.width,
            y: point.y / videoRect.height
        )
        return normalizedPoint
    }

    private func getEditScriptFrameTime() -> CMTime {
        let script = asset.cinematicAssetData.script
        let frames = script.frames(in: script.timeRange)
        // Calculate the frame index that corresponds to the normalized `timelinePosition`.
        var frameIndex = Int(asset.editTimelinePosition * Double(frames.count))
        if frameIndex == frames.count {
            frameIndex -= 1
        }
        let time = frames[frameIndex].time
        return time
    }
}
