/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that contains utilities to handle user interaction with a Cinematic mode video.
*/

import CoreMedia
import AVFoundation
import Cinematic
import OSLog

class SampleObjectTracking {

    private var cinematicObjectTracker: CNObjectTracker
    private var cinematicAssetReader: CinematicAssetReader?

    init(commandQueue: MTLCommandQueue) {
        self.cinematicObjectTracker = CNObjectTracker(commandQueue: commandQueue)
        self.cinematicAssetReader = nil
    }

    // Find an object, and start tracking at a given point in the current frame.
    private func findObjectAndStartTracking(pointOfInterest: CGPoint) -> Bool {
        guard let cinematicAssetReader = self.cinematicAssetReader else {
            fatalError("No Asset Reader")
        }
        let cinematicAssetSampleBuffer = cinematicAssetReader.getNextSampleBuffer()
        guard let imageBuffer = cinematicAssetSampleBuffer.imageBuffer else {
            fatalError("No image buffer")
        }
        guard let disparityBuffer = cinematicAssetSampleBuffer.disparityBuffer else {
            fatalError("No disparity buffer")
        }
        guard let presentationTimeStamp = cinematicAssetSampleBuffer.presentationTimeStamp else {
            fatalError("No timestamp")
        }

        // Find an object.
        let cinematicObjectTrackerPrediction =
        cinematicObjectTracker.findObject(at: pointOfInterest, sourceImage: imageBuffer)
        if let normalizedRect = cinematicObjectTrackerPrediction?.normalizedBounds {
            // If the object is found, start tracking it.
            let result = cinematicObjectTracker.startTracking(at: presentationTimeStamp,
                                                           within: normalizedRect,
                                                           sourceImage: imageBuffer,
                                                           sourceDisparity: disparityBuffer)
            if !result {
                print("Couldn't start tracking")
                return false
            }
            print("Started tracking")
            return true
        } else {
            print("No rect found at \(pointOfInterest)")
            return false
        }
    }

    func handleObjectTracking(cinematicAssetData: CinematicAssetData,
                              pointOfInterest: CGPoint,
                              timeRange: CMTimeRange,
                              strongDecision: Bool) async {
        self.cinematicAssetReader = CinematicAssetReader(cinematicAssetData: cinematicAssetData)
        guard let cinematicAssetReader = self.cinematicAssetReader else {
            fatalError("No Asset Reader")
        }
        cinematicAssetReader.setupForReading(timeRange: timeRange)
        // Find an object, and start tracking.
        let result = findObjectAndStartTracking(pointOfInterest: pointOfInterest)
        if !result {
            cinematicAssetReader.cancelReading()
            self.cinematicAssetReader = nil
            return
        }

        // Iterate over frames to continue tracking.
        var cinematicAssetSampleBuffer = cinematicAssetReader.getNextSampleBuffer()

        while cinematicAssetSampleBuffer.imageBuffer != nil {

            let imageBuffer = cinematicAssetSampleBuffer.imageBuffer!
            guard let disparityBuffer = cinematicAssetSampleBuffer.disparityBuffer else {
                fatalError("No disparity buffer")
            }
            guard let presentationTimeStamp =
                    cinematicAssetSampleBuffer.presentationTimeStamp else {
                fatalError("No timestamp")
            }
            cinematicAssetSampleBuffer = cinematicAssetReader.getNextSampleBuffer()

            // Continue tracking.
            if let objectPrediction =
                cinematicObjectTracker.continueTracking(at: presentationTimeStamp,
                                                     sourceImage: imageBuffer,
                                                     sourceDisparity: disparityBuffer) {
                if objectPrediction.normalizedBounds.isEmpty {
                    break
                }
            } else {
                break
            }
        }
        // Finish and add a detection track.
        let detectionTrack = cinematicObjectTracker.finishDetectionTrack()
        let detectionID = cinematicAssetData.script.addDetectionTrack(detectionTrack)
        let cinematicDecision = CNDecision(time: timeRange.start,
                                           detectionID: detectionID,
                                           strong: strongDecision)
        // Add the user decision.
        let res = cinematicAssetData.script.addUserDecision(cinematicDecision)
        if res {
            print("Added detection successfully")
        }
        cinematicAssetReader.cancelReading()
        self.cinematicAssetReader = nil
    }
}
