/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Creates a mutable composition from the supplied clips and time ranges, and
renders these with a video composition.
*/

import Foundation
import AVFoundation
import UIKit

let transitionInSeconds = 2.0

// MARK: - Source Clip
/// A structure that describes a video and its associated attributes.
struct SourceClip {
    var asset: AVURLAsset
    // The time range of the original video to include in the composition.
    var availableTimeRange: CMTimeRange

    init(assetURL: AVURLAsset, timeRange: CMTimeRange) {
        asset = assetURL
        availableTimeRange = timeRange
    }
}

class SimpleEditor: NSObject, AVVideoCompositionValidationHandling {
    private let frameDuration: Int32 = 30

    /// The movie clips in the composition.
    private var clips = [SourceClip]()

    /// The duration in seconds of each clip.
    private let clipTimeRangeInSeconds: Float = 5.0

    /// The composition to add the tracks from the media assets to.
    private lazy var editorComposition: AVMutableComposition = {
        var comp = AVMutableComposition()
        // Use the naturalSize of the first video track.
        comp.naturalSize = SimpleEditorUtils.naturalSize(ofVideo: clips[0].asset)

        // Add two empty video and audio tracks to the composition.
        SimpleEditorUtils.addEmptyTracks(ofType: AVMediaType.video, to: comp)
        SimpleEditorUtils.addEmptyTracks(ofType: AVMediaType.audio, to: comp)
                
        return comp
    }()
    
    private var editorAudioMix = AVMutableAudioMix()

    /**
     A video composition that describes the number and IDs of video tracks to produce a composed video frame.
    */
    private lazy var editorVideoComposition: AVMutableVideoComposition = {
        var videoComp = AVMutableVideoComposition()
        // The following properties are required for every video composition.
        videoComp.frameDuration = CMTimeMake(value: 1, timescale: frameDuration)
        videoComp.renderSize = editorComposition.naturalSize
        return videoComp
    }()

    /// The duration of the transition effect.
    private lazy var transitionDuration: CMTime = {
        var clipTimeRanges = [CMTimeRange]()
        for clip in self.clips {
            clipTimeRanges.append(clip.availableTimeRange)
        }
        // Use a minimum 2.0 second transition duration for the effect.
        let defaultDuration = CMTimeMakeWithSeconds(transitionInSeconds, preferredTimescale: Int32(NSEC_PER_SEC))
        var duration = defaultDuration
        /*
         Make the transitionDuration no greater than half the shortest clip
         duration.
        */
        for index in 0..<clipTimeRanges.count {
            let clipTimeRange = clipTimeRanges[index]
            var halfClipDuration = clipTimeRange.duration
            // Halve a rational by doubling its denominator.
            halfClipDuration.timescale *= 2
            duration = CMTimeMinimum(duration, halfClipDuration)
        }
        return duration
    }()
    
    /// The time range in which the clips should pass through.
    private lazy var passThroughTimeRanges: [CMTimeRange] = {
        Array(repeating: CMTimeRangeMake(start: CMTime.zero, duration: CMTime.zero), count: clips.count)
    }()
    /// The transition time range for the clips.
    private lazy var transitionTimeRanges: [CMTimeRange]  = {
        Array(repeating: CMTimeRangeMake(start: CMTime.zero, duration: CMTime.zero), count: clips.count)
    }()
    
    private let assetQueue = DispatchQueue(label: "assetQueue")
    private let assetGroup = DispatchGroup()
    private let assetKeys: [String] = ["playable", "hasProtectedContent", "composable"]
    
    // MARK: - Initialization
    init(completion: @escaping () -> Void) {
        super.init()
        prepare(assets: mediaAssets(), completion: {
            if self.clips.count > 1 {
                if self.createComposition() {
                    self.createVideoCompAndAudioMix()
                }
            } else {
                SimpleEditorUtils.display("The editor composition requires at least 2 clips", error: nil)
            }
            completion()
        })
    }

    // MARK: - Asset (Clips) Loading
    ///  Returns an array of all the movie assets in the project.
    private func mediaAssets() -> [AVAsset] {
        var mediaAssets: [AVURLAsset] = []
        guard let movieURLs = Bundle.main.urls(forResourcesWithExtension: ".mov", subdirectory: nil) else {
            return mediaAssets
        }
        for movieURL in movieURLs {
            mediaAssets.append(AVURLAsset(url: movieURL))
        }
        return mediaAssets
    }
    
    /// Saves the provided asset in the sourceClips array for subsequent processing.
    private func store(asset: AVAsset) {
        /*
         Note: The sample stitches together short clips from each video file, one after another, in a
         composition. When merging portions of a video file like this, it's important not to pick arbitrary
         transition points. Consider frame durations when stitching together content. Otherwise, stitching
         together clips at arbitrary points can result in audio glitches and pops, and may cut off some video
         frames. For these reasons, the sample aligns the media content based on the frame durations. To do
         that, it determines where the frame nearest to the transition point begins, and then stitches the
         clips together at that point.
        */
        if let assetURL = asset as? AVURLAsset {
            /*
             Get the presentation timestamp for the media sample buffer nearest the transition point. Use that
             for stitching the clips together. Stitching together clips at arbitrary points can result in
             audio glitches and pops, and may cut off some video frames.
            */
            let audioSampleBufferPTS =
            SimpleEditorUtils.sampleBufferPTS(nearest: clipTimeRangeInSeconds,
                                              of: asset,
                                              forType: AVMediaType.audio)
            let videoSampleBufferPTS =
            SimpleEditorUtils.sampleBufferPTS(nearest: clipTimeRangeInSeconds,
                                              of: asset,
                                              forType: AVMediaType.video)
            var sampleBufferPTS = videoSampleBufferPTS
            /*
             The audio and video frames might not have the same presentation timestamp values at the
             transition point. Generally, video follows audio timing, so the sample aligns using the audio
             timestamp to keep the audio and video in sync (because audio sounds odd if stitched improperly,
             but when a video frame's duration is longer or shorter, it isn't as noticeable).
            */
            if CMTimeCompare(audioSampleBufferPTS, videoSampleBufferPTS) != 0 {
                sampleBufferPTS = audioSampleBufferPTS
            }
            let start = CMTimeMakeWithSeconds(0, preferredTimescale: sampleBufferPTS.timescale)
            // Use only the first few seconds of each video.
            let clipRange = CMTimeRange(start: start, duration: sampleBufferPTS)
            // Save the asset.
            self.clips.append(SourceClip(assetURL: assetURL, timeRange: clipRange))
        }
    }

    /**
     Determines whether an asset is suitable for use in the app. A suitable asset has playable content, is valid as a
     segment of a composition track, and doesn't contain protected content.
    */
    private func suitable(_ asset: AVAsset) -> Bool {
        if !asset.isComposable {
            SimpleEditorUtils.display("The asset is not composable.", error: nil)
            return false
        }
        
        if !asset.isPlayable {
            // You can't play the asset. The asset can't initialize a player item.
            SimpleEditorUtils.display("The asset isn't playable.", error: nil)
            return false
        }
        
        if asset.hasProtectedContent {
            // You can't play the asset. The asset contains protected content.
            SimpleEditorUtils.display("The asset contains protected content.", error: nil)
            return false
        }
        return true
    }
    
    /// Confirm the successfull loading of all the asset's keys and verify their values.
    private func loaded(_ keys: [String], of asset: AVAsset) -> Bool {
        var propertyValuesLoaded = false
        // Check whether the values of each of the keys successfully load.
        for item in keys {
            var error: NSError?
            switch asset.statusOfValue(forKey: item, error: &error) {
                case AVKeyValueStatus.loaded:
                    propertyValuesLoaded = true
                case AVKeyValueStatus.failed:
                    SimpleEditorUtils.display("The attempt to load the asset key failed.")
                    propertyValuesLoaded = false
                case AVKeyValueStatus.cancelled:
                    SimpleEditorUtils.display("Key loading was cancelled.")
                    propertyValuesLoaded = false
                default:
                    SimpleEditorUtils.display("Key loading failed.")
                    propertyValuesLoaded = false
            }
        }
        return propertyValuesLoaded
    }
    
    /**
     Load the values of the specified asset keys (property names) before attempting playback. Asset initialization
     doesn't ensure the availability of all the asset keys. Use the AVAsynchronousKeyValueLoading
     protocol to ask for values and get an answer back later through a completion handler rather than blocking the
     current thread while calculating a value.
    */
    private func load(keys: [String], for asset: AVAsset) {
        var loadedAndSuitable = false
        asset.loadValuesAsynchronously(forKeys: keys, completionHandler: { [self] in
            if loaded(keys, of: asset) {
                loadedAndSuitable = suitable(asset)
            }
            if loadedAndSuitable {
                assetQueue.sync {
                    self.store(asset: asset)
                }
            }
            self.assetGroup.leave()
        })
    }

    /// Prepare the asset for playback.
    private func prepare(assets: [AVAsset], completion: @escaping () -> Void) {
        for asset in assets {
            self.assetGroup.enter()
                // Load all the specified keys of the asset.
            self.load(keys: self.assetKeys, for: asset)
        }
        assetGroup.notify(queue: DispatchQueue.main) {
            completion()
        }
    }

    // MARK: - Composition, Video Composition, and Audio Mix
    private func createComposition() -> Bool {
        let compVideoTrks = editorComposition.tracks(withMediaType: AVMediaType.video)
        let compAudioTrks = editorComposition.tracks(withMediaType: AVMediaType.audio)
        
        /*
         Place the clips into alternating video and audio tracks in the composition,
         and overlap them with transitionDuration. Set up the video composition to cycle
         between "pass through A", "transition from A to B", and "pass through B".
        */
        var nextClipStart = CMTime.zero
        for clipIndex in 0..<clips.count {
            // Alternating targets: 0, 1, 0, 1, ...
            let asset = clips[clipIndex].asset
            let clipTimeRange = clips[clipIndex].availableTimeRange
            do {
                let clipVideoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
                try compVideoTrks[clipIndex % 2].insertTimeRange(clipTimeRange, of: clipVideoTrack, at: nextClipStart)
                let clipAudioTracks = asset.tracks(withMediaType: AVMediaType.audio)
                if clipAudioTracks.isEmpty {
                    SimpleEditorUtils.display("Each clip must have an audio track.")
                    return false
                }
                try compAudioTrks[clipIndex % 2].insertTimeRange(clipTimeRange, of: clipAudioTracks[0], at: nextClipStart)
            } catch {
                SimpleEditorUtils.display("Error inserting a track into the composition:\(error).")
               return false
            }
            /*
             Retain the time range for this clip to pass through. The first clip ends with a transition.
             The second clip begins with a transition. Exclude that transition from the passthrough time ranges.
            */
            passThroughTimeRanges[clipIndex] = CMTimeRangeMake(start: nextClipStart, duration: clipTimeRange.duration)
            if clipIndex > 0 {
                passThroughTimeRanges[clipIndex].start = CMTimeAdd(passThroughTimeRanges[clipIndex].start,
                                transitionDuration)
            }
            passThroughTimeRanges[clipIndex].duration = CMTimeSubtract(passThroughTimeRanges[clipIndex].duration,
                                transitionDuration)

            /*
             The end of this clip overlaps the start of the next by transitionDuration. (Note: This fails if
             timeRangeInAsset.duration < 2 * transitionDuration.)
            */
            nextClipStart = CMTimeSubtract(CMTimeAdd(nextClipStart, clipTimeRange.duration), transitionDuration)

            // Retain the time range for the transition to the next item.
            if clipIndex + 1 < clips.count {
                transitionTimeRanges[clipIndex] = CMTimeRangeMake(start: nextClipStart, duration: transitionDuration)
            }
        }
        return true
    }

    private func createVideoCompAndAudioMix() {
        var alternatingIndex = 0

        // Set up the video composition to perform transitions between clips.
        var instructions = [AVVideoCompositionInstructionProtocol]()
        var trackMixArray = [AVMutableAudioMixInputParameters]()

        let compVideoTracks = editorComposition.tracks(withMediaType: AVMediaType.video)
        let compAudioTracks = editorComposition.tracks(withMediaType: AVMediaType.audio)

        // Cycle between "pass through A", "transition from A to B", and "pass through B".
        for currIndex in 0..<clips.count {
            alternatingIndex = currIndex % 2 // Alternating targets.

            // Pass through clip i.
            let passThroughInstruction = AVMutableVideoCompositionInstruction()
            passThroughInstruction.timeRange = passThroughTimeRanges[currIndex]
            let passThroughLayer = AVMutableVideoCompositionLayerInstruction(assetTrack:
                                    compVideoTracks[alternatingIndex])
            passThroughInstruction.layerInstructions = [passThroughLayer]
            instructions.append(passThroughInstruction)

            if currIndex + 1 < clips.count {
                // Add a transition from clip i to clip i+1.
                let transitionInstruction = AVMutableVideoCompositionInstruction()
                transitionInstruction.timeRange = transitionTimeRanges[currIndex]
                let fromLayer = AVMutableVideoCompositionLayerInstruction(assetTrack:
                                    compVideoTracks[alternatingIndex])
                let toLayer = AVMutableVideoCompositionLayerInstruction(assetTrack:
                                compVideoTracks[1 - alternatingIndex])
                // Set an opacity ramp to apply during the specified time range.
                toLayer.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0,
                                    timeRange: transitionTimeRanges[currIndex])

                transitionInstruction.layerInstructions = [toLayer, fromLayer]
            
                instructions.append(transitionInstruction)
            
                // Add an audio mix to the first clip to fade in the volume ramps.
                let trackMix1 = AVMutableAudioMixInputParameters(track: compAudioTracks[0])
                trackMix1.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0,
                                        timeRange: transitionTimeRanges[0])
            
                trackMixArray.append(trackMix1)
            
                // Add an audio mix to the second clip to fade out the volume ramps.
                let trackMix2 = AVMutableAudioMixInputParameters(track: compAudioTracks[1])
                trackMix2.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 1.0,
                                        timeRange: transitionTimeRanges[0])
                trackMix2.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 1.0,
                                        timeRange: passThroughTimeRanges[1])
                trackMixArray.append(trackMix2)
            }
        }
        editorAudioMix.inputParameters = trackMixArray
        editorVideoComposition.instructions = instructions
    }

    // MARK: - Accessors
    func audioMix() -> AVMutableAudioMix { return editorAudioMix }

    func composition() -> AVMutableComposition { return editorComposition }

    func videoComposition() -> AVMutableVideoComposition {
        return editorVideoComposition
    }
    
    // MARK: - Video Composition Validation Handling
    /*
     Methods you can implement to indicate whether validation of a video composition
     continues after finding specific errors.
    */
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingEmptyTimeRange timeRange: CMTimeRange) -> Bool {
            SimpleEditorUtils.display("Empty time range detected during validation.")
            return false // Stop validation after finding errors.
    }
    
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTimeRangeIn videoCompositionInstruction: AVVideoCompositionInstructionProtocol) -> Bool {
            SimpleEditorUtils.display("Invalid time range detected during validation.")
            return false // Stop validation after finding errors.
    }
    
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidValueForKey key: String) -> Bool {
            SimpleEditorUtils.display("Invalid value for \(key) detected during validation.")
            return false // Stop validation after finding errors.
    }
    
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTrackIDIn videoCompositionInstruction: AVVideoCompositionInstructionProtocol, layerInstruction: AVVideoCompositionLayerInstruction, asset: AVAsset) -> Bool {
            SimpleEditorUtils.display("Invalid track ID detected during validation.")
            return false // Stop validation after finding errors.
    }
}
