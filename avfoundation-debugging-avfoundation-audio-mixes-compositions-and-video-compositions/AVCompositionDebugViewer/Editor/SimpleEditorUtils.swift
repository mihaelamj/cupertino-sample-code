/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains utility functions that the simple editor uses for working with tracks,
 presentation timestamps, and displaying errors.
*/

import Foundation
import AVFoundation
import UIKit

class SimpleEditorUtils: NSObject {
    
    // MARK: - Track Utilities

    /// Returns the natural dimensions of the media data that the track references.
    class func naturalSize(ofVideo video: AVURLAsset) -> CGSize {
        let videoTracks = video.tracks(withMediaType: AVMediaType.video)
        return videoTracks[0].naturalSize
    }
  
    /// Adds two empty tracks of the specified media type to the composition.
    class func addEmptyTracks(ofType type: AVMediaType, to composition: AVMutableComposition) {
        for _ in 0...1 {
            composition.addMutableTrack(withMediaType: type, preferredTrackID: kCMPersistentTrackID_Invalid)
        }
    }
    
    // MARK: - Presentation Timestamp Utilities

    /// Get the presentation timestamp for the sample buffer nearest the specified time in seconds in the asset.
    class func sampleBufferPTS(nearest seconds: Float,
                               of asset: AVAsset,
                               forType mediaType: AVMediaType) -> CMTime {
        
        var assetReader: AVAssetReader!
        var trackOutput: AVAssetReaderTrackOutput!
        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            return CMTime.invalid
        }

        // Get the first media track.
        let tracks = asset.tracks(withMediaType: mediaType)
        guard let track = tracks.first else { return CMTime.invalid }

        // Specify the settings to use for the sample output.
        var outputSettingsDict: [String: Any]
        if mediaType == AVMediaType.video {
            outputSettingsDict = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_32ARGB,
            String(kCVPixelBufferIOSurfacePropertiesKey): [:]
            ]
        } else {
            outputSettingsDict =
                [ String(AVFormatIDKey): kAudioFormatLinearPCM ]
        }
        
        // Create an AVAssetReaderTrackOutput to read media from the track.
        trackOutput = AVAssetReaderTrackOutput(track: track,
                        outputSettings: outputSettingsDict)
        if assetReader.canAdd(trackOutput) {
            assetReader.add(trackOutput)
        } else {
            return CMTime.invalid
        }
        
        // Calculate the frame duration from the track.
        let minFrameDuration = frameDuration(from: track)

        /*
         Specify a time range centered around the transition point to read
         sample buffers from the asset. The time range start value is offset a
         few frame durations before the transition point, and the time range
         end value is offset a few frame durations after the transition point.
        */
        let timeRange =
            timeRange(using: minFrameDuration, around: Float64(seconds))
        assetReader.timeRange = timeRange

        let success = assetReader.startReading()
        if !(success) {
            return CMTime.invalid
        }
        
        var ptsValues: [CMTime] = []
        // Read the sample buffers.
        while assetReader.status == AVAssetReader.Status.reading {
            // Copies the next sample buffer for the output.
            if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                if CMSampleBufferIsValid(sampleBuffer) {
                    let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    /*
                     Save the presentation timestamps for each sample buffer in
                     an array for processing.
                    */
                    ptsValues.append(timeStamp)
                }
            }
        }
        
        /*
         Return the presentation timestamp of the sample buffer nearest the
         transition time.
        */
        let transitionTime =
            CMTimeMakeWithSeconds(Float64(seconds),
                                preferredTimescale: minFrameDuration.timescale)
        return pts(in: ptsValues, nearest: transitionTime)
    }
    
    /**
     Find the presentation timestamp (PTS) value in the array of CMTime values closest to the target time.
    */
    class func pts(in ptsValues: [CMTime], nearest target: CMTime) -> CMTime {
        // Get the index of the PTS array value nearest the transition point.
        let index = index(of: ptsValues, nearest: target)
        // Return the presentation timestamp value.
        return ptsValues[index]
    }
            
    /**
     Find the number in the array closest to the specified target value, then return its index value.
    */
    class func index(of ptsValues: [CMTime], nearest target: CMTime) -> Int {
        var left = 0, right = ptsValues.count - 1
        while left + 1 < right {
            let midIndex = left + (right - left) / 2
            if CMTimeCompare(ptsValues[midIndex], target) == 0 {
                return midIndex
            } else if CMTimeCompare(ptsValues[midIndex], target) == 1 {
                right = midIndex
            } else {
                left = midIndex
            }
        }
        
        /*
         Computes the difference between two times and returns the absolute
         value of that difference.
        */
        let absDiff: (CMTime, CMTime) -> CMTime = { (number, target) in
            let difference = CMTimeSubtract(number, target)
            return CMTimeAbsoluteValue(difference)
        }
        
        let diffLeft = absDiff(ptsValues[left], target)
        let diffRight = absDiff(ptsValues[right], target)
        if CMTimeCompare(diffLeft, diffRight) == -1 || CMTimeCompare(diffLeft, diffRight) == 0 {
            return left
        }

        return right
    }
    
    /// Get the frame duration from the track information.
    class func frameDuration(from track: AVAssetTrack) -> CMTime {
        var minFrameDuration = track.minFrameDuration
        if minFrameDuration == CMTime.invalid {
            minFrameDuration =
                CMTimeMake(value: 1, timescale: Int32(track.naturalTimeScale))
        }
        
        return minFrameDuration
    }
    
    /**
     Calculate a time range centered around a given transition point.
     The time range start value is offset a few frame durations before the
     transition point, and the time range end value is offset a few frame
     durations after the transition point.
     */
    class func timeRange(using frameDuration: CMTime,
                         around transitionPt: Float64) -> CMTimeRange {
        let transitionTime =
            CMTimeMakeWithSeconds(Float64(transitionPt),
                                preferredTimescale: frameDuration.timescale)
        let frameOffset = 6
        let expandedRange =
            CMTimeMultiply(frameDuration, multiplier: Int32(frameOffset))
        let newRangeStart = CMTimeSubtract(transitionTime, expandedRange)
        let newRangeEnd = CMTimeMultiply(frameDuration,
                                         multiplier: Int32(frameOffset * 2))
        return CMTimeRangeMake(start: newRangeStart, duration: newRangeEnd)
    }
    
    // MARK: - Error Handling
    /// Display a message and error value.
    class func display(_ message: String, error: Error? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: message,
                        message: error?.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK",
                        comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
            }))
            var rootViewController = UIApplication.shared.windows.first!.rootViewController
            if let navigationController =
                rootViewController as? UINavigationController {
                rootViewController = navigationController.viewControllers.first
            }
            if let tabBarController =
                rootViewController as? UITabBarController {
                rootViewController = tabBarController.selectedViewController
            }
            rootViewController?.present(alertController, animated: true, completion: nil)
        }
    }

}
