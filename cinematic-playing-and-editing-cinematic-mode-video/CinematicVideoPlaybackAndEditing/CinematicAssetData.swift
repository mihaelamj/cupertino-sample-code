/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that holds the Cinematic mode data of an asset.
*/

import CoreMedia
import AVFoundation
import Cinematic
import Photos
import PhotosUI

struct CinematicAssetData {

    let avAsset: AVAsset
    let assetInfo: CNAssetInfo
    let renderingSessionAttributes: CNRenderingSession.Attributes
    let renderingSession: CNRenderingSession
    let commandQueue: MTLCommandQueue
    let script: CNScript
    let nominalFrameRate: Float
    let naturalTimeScale: CMTimeScale
}

extension CinematicAssetData {

    func makeVideoComposition() -> (AVComposition, AVVideoComposition) {

        let avComposition = AVMutableComposition()

        // Use `CNCompositionInfo` for setting up the track information.
        let compositionInfo: CNCompositionInfo =
            avComposition.addTracks(for: assetInfo,
                                    preferredStartingTrackID: kCMPersistentTrackID_Invalid)

        do {
            try compositionInfo.insertTimeRange(assetInfo.timeRange, of: assetInfo, at: CMTime.zero)
        } catch {
            fatalError("Couldn't insert timerange")
        }

        let instruction = SampleCompositionInstruction(renderingSession: renderingSession,
                                                       compositionInfo: compositionInfo,
                                                       script: script,
                                                       fNumber: script.fNumber, editMode: false)

        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.sourceTrackIDForFrameTiming = compositionInfo.frameTimingTrack.trackID
        mutableVideoComposition.sourceSampleDataTrackIDs = compositionInfo.sampleDataTrackIDs
        mutableVideoComposition.customVideoCompositorClass = SampleCustomCompositor.self
        mutableVideoComposition.instructions = [instruction]

        if nominalFrameRate <= 0 {
            mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        } else {
            mutableVideoComposition.frameDuration = CMTimeMakeWithSeconds(1.0 / Double(nominalFrameRate),
                                                                preferredTimescale: naturalTimeScale)
        }

        // Use the preferred size for the display orientation.
        mutableVideoComposition.renderSize = assetInfo.preferredSize

        return (avComposition, mutableVideoComposition)
    }
}
