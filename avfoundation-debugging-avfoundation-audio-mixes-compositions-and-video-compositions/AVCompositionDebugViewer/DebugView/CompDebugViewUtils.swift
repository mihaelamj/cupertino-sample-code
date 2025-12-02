/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions that the composition debug view uses.
*/

import Foundation
import UIKit
import AVFoundation

/// A utility to calculate a height value to use when drawing the various elements in the composition in the debug view.
func rowHeight(from viewHeight: CGFloat, bannerCount: Int, rowCount: Int) -> Int {
    let totalBannerHeight = bannerCount * (Banner.height.rawValue + Banner.gapAfterRows.rawValue)
    var rowHeight = Banner.idealRowHeight.rawValue
    if rowCount > 0 {
        let maxRowHeight = (viewHeight - CGFloat(totalBannerHeight)) / CGFloat(rowCount)
        rowHeight = min(rowHeight, Int(maxRowHeight))
    }
    
    return rowHeight
}

/// Returns an array of fully initialized CompositionTrackSegmentInfo structures for the provided composition tracks.
func trackSegmentInfo(from tracks: [AVCompositionTrack]) -> [[CompositionTrackSegmentInfo]] {
    var compTrackSegmentInfo = [[CompositionTrackSegmentInfo]]()
    
    for track in tracks {
        compTrackSegmentInfo.append(trackSegmentInfo(from: track.segments, ofMediaType: track.mediaType))
    }
    
    return compTrackSegmentInfo
}

/// Returns an array of CompositionTrackSegmentInfo structures for the provided composition track segments.
private func trackSegmentInfo(from segments: [AVCompositionTrackSegment],
                              ofMediaType mediaType: AVMediaType) -> [CompositionTrackSegmentInfo] {
    var trackSegmentInfo = [CompositionTrackSegmentInfo]()
    for segment in segments {
        var segmentInfo = CompositionTrackSegmentInfo()
        if segment.isEmpty {
            segmentInfo.timeRange = segment.timeMapping.target
        } else {
            segmentInfo.timeRange = segment.timeMapping.source
        }
        
        segmentInfo.empty = segment.isEmpty
        segmentInfo.mediaType = mediaType
        if segmentInfo.empty == false {
            let startTime = CMTimeGetSeconds(segmentInfo.timeRange.start)
            let endTime = CMTimeGetSeconds(CMTimeRangeGetEnd(segmentInfo.timeRange))
            let fileName = String(describing: segment.sourceURL?.lastPathComponent)
            var description = "\(startTime) - \(endTime) : \(fileName)"

            if segmentInfo.mediaType == AVMediaType.video {
                description += "(v)"
            } else if segmentInfo.mediaType == AVMediaType.audio {
                description += "(a)"
            } else {
                description += "\(segmentInfo.mediaType.rawValue)"
            }
            segmentInfo.description = description
        }
        trackSegmentInfo.append(segmentInfo)
    }
    return trackSegmentInfo
}

/// Returns an array of CGPoints corresponding to the volume ramp in the provided AVAudioMix.
func volumeRampPoints(from audioMix: AVAudioMix, duration: CMTime) -> [[CGPoint]] {
    var volumeRampAsPoints = [[CGPoint]]()
    for input in audioMix.inputParameters {
        var ramp = [CGPoint]()
        var startTime = CMTime.zero
        var startVolume: Float = 0.0, endVolume: Float = 1.0
        var timeRange = CMTimeRange()
        while input.getVolumeRamp(for: startTime, startVolume: &startVolume,
                                endVolume: &endVolume, timeRange: &timeRange) {
            if CMTimeCompare(startTime, CMTime.zero) ==
                0 && CMTimeCompare(timeRange.start, CMTime.zero) == 1 {
                ramp.append(CGPoint(x: 0, y: 1.0))
                ramp.append(CGPoint(x: CMTimeGetSeconds(timeRange.start), y: 1.0))
            }
            ramp.append(CGPoint(x: CMTimeGetSeconds(timeRange.start), y: Double(startVolume)))
            ramp.append(CGPoint(x: CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange)), y: Double(endVolume)))
            startTime = CMTimeRangeGetEnd(timeRange)
        }
        if CMTimeCompare(startTime, duration) == -1 {
            ramp.append(CGPoint(x: CMTimeGetSeconds(duration), y: Double(endVolume)))
        }
        volumeRampAsPoints.append(ramp)
    }
    
    return volumeRampAsPoints
}

/// Returns an array of points corresponding to the opacity ramp in the provided AVVideoCompositionLayerInstruction.
private func ramps(from layerInstruction: AVVideoCompositionLayerInstruction) -> [NSValue] {
    var ramps = [NSValue]()
    var startTime = CMTime.zero
    var startOpacity: Float = 1.0, endOpacity: Float = 1.0
    var timeRange = CMTimeRange()
    while layerInstruction.getOpacityRamp(for: startTime, startOpacity:
            &startOpacity, endOpacity: &endOpacity, timeRange: &timeRange) {
        if CMTimeCompare(startTime, CMTime.zero) ==
            0 && CMTimeCompare(timeRange.start, CMTime.zero) == 1 {
            ramps.append(NSValue(cgPoint: CGPoint(x: CMTimeGetSeconds(timeRange.start),
                    y: Double(startOpacity))))
        }
        ramps.append(NSValue(cgPoint: CGPoint(x: CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange)),
                y: Double(endOpacity))))
        startTime = CMTimeRangeGetEnd(timeRange)
    }
            
    return ramps
}

/// Returns an array of VideoCompositionStageInfo structures that the system creates from the provided array of AVVideoCompositionInstruction.
func videoCompStageInfo( from instructions: [AVVideoCompositionInstructionProtocol])
            -> [VideoCompositionStageInfo] {
    var videoCompositionStages = [VideoCompositionStageInfo]()
    for instruction in instructions {
        var stage = VideoCompositionStageInfo()
        stage.timeRange = instruction.timeRange

        var rampsDictionary = [String: [NSValue]]()
        var layerNames = [String]()
        /*
         In Objective-C, AVVideoCompositionInstruction is the name of a protocol,
         as well as the name of an interface (see AVVideoCompositing.h and
         AVVideoComposition.h). In Swift, you can't have the same name for
         both a protocol and a class. Therefore, the AVFoundation framework
         names the protocol AVVideoCompositionInstructionProtocol.
         Consequently, in Swift you must downcast from
         AVVideoCompositionInstructionProtocol to
         AVVideoCompositionInstruction.
        */
        let instr = instruction as! AVVideoCompositionInstruction
        for layerInstruction in instr.layerInstructions {

            let name = layerInstruction.trackID.description
            layerNames.append(name)
            rampsDictionary[name] = ramps(from: layerInstruction)
        }
        
        if layerNames.count > 1 {
            stage.opacityRamps = rampsDictionary
        }
        
        stage.layerNames = layerNames as [String]
        videoCompositionStages.append(stage)
    }
    return videoCompositionStages
}

