/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The representation of a video file, and the function to process the video and return the top three thumbnails.
*/

import Vision
import AVFoundation
import SwiftUI

/// The structural representation of a video file.
struct VideoFile {
    /// The local path to the video file.
    var url: URL
}

/// The structure that holds frame information before creating a thumbnail.
struct Frame {
    /// The timestamp of the frame.
    let time: CMTime

    /// The score of the frame.
    let score: Float

    /// The feature-print observation of the frame.
    let observation: FeaturePrintObservation
}

// MARK: Process the video.
/// Process the video and return the top-rated thumbnails.
func processVideo(for videoURL: URL, progression: Binding<Float>) async -> [Thumbnail] {
    /// The instance of the `VideoProcessor` with the local path to the video file.
    let videoProcessor = VideoProcessor(videoURL)

    /// The request to calculate the aesthetics score for each frame.
    let aestheticsScoresRequest = CalculateImageAestheticsScoresRequest()

    /// The request to generate feature prints from an image.
    let imageFeaturePrintRequest = GenerateImageFeaturePrintRequest()

    /// The array to store information for the frames with the highest scores.
    var topFrames: [Frame] = []

    /// The asset that represents video at a local URL to process the video.
    let asset = AVURLAsset(url: videoURL)

    do {
        /// The total duration of the video in seconds.
        let totalDuration = try await asset.load(.duration).seconds

        /// The number of frames to evaluate.
        let framesToEval: Double = 100

        /// The preferred timescale for the interval.
        let timeScale: CMTimeScale = 600

        /// The time interval for the video-processing cadence.
        let interval = CMTime(
            seconds: totalDuration / framesToEval,
            preferredTimescale: timeScale
        )

        /// The video-processing cadence to process only 100 frames.
        let cadence = VideoProcessor.Cadence.timeInterval(interval)

        /// The stream that adds the aesthetics scores request to the video processor.
        let aestheticsScoreStream = try await videoProcessor.addRequest(aestheticsScoresRequest, cadence: cadence)

        /// The stream that adds the image feature-print request to the video processor.
        let featurePrintStream = try await videoProcessor.addRequest(imageFeaturePrintRequest, cadence: cadence)

        // Start to analyze the video.
        videoProcessor.startAnalysis()

        /// The dictionary to store the timestamp and the aesthetics score.
        var aestheticsResults: [CMTime: Float] = [:]

        /// The dictionary to store the timestamp and the feature-print observation.
        var featurePrintResults: [CMTime: FeaturePrintObservation] = [:]

        var count = 0

        // Go through the video stream to fill in `aestheticsResults`.
        for try await observation in aestheticsScoreStream {
            if let timeRange = observation.timeRange {
                aestheticsResults[timeRange.start] = observation.overallScore

                count += 1

                // Update progress with the current time and total duration.
                progression.wrappedValue = Float(timeRange.start.seconds / totalDuration)
            }
        }

        print("\(count)")

        // Go through the video stream to fill in `featurePrintResults`.
        for try await observation in featurePrintStream {
            if let timeRange = observation.timeRange {
                featurePrintResults[timeRange.start] = observation
            }
        }

        // Solve for the top-rated frames.
        topFrames = await calculateTopFrames(aestheticsResults: aestheticsResults, featurePrintResults: featurePrintResults)
    } catch {
        fatalError("Error processing video: \(error.localizedDescription)")
    }

    return await generateThumbnails(from: topFrames, videoURL: videoURL, with: asset)
}

// MARK: Solve for the top-rated frames.
/// Calculate the top-rated frames based on aesthetics scores and feature-print observations.
func calculateTopFrames(aestheticsResults: [CMTime: Float], featurePrintResults: [CMTime: FeaturePrintObservation]) async -> [Frame] {
    /// The number of frames to store.
    let maxTopFrames = 3

    /// The array to store information for the frames with the highest scores.
    var topFrames: [Frame] = []

    /// The threshold for counting the image distance as similar.
    let similarityThreshold = 0.3

    for (time, score) in aestheticsResults {
        /// The `FeaturePrintObservation` for the timestamp.
        guard let featurePrint = featurePrintResults[time] else { continue }

        /// The new frame at that timestamp.
        let newFrame = Frame(time: time, score: score, observation: featurePrint)

        /// The variable that tracks whether to add the image based on image similarity.
        var isSimilar = false

        /// The variable to track the index to insert the new frame.
        var insertionIndex = topFrames.count

        // Iterate through the current top-rated frames to check whether any of them
        // are similar to the new frame and find the insertion index.
        for (index, frame) in topFrames.enumerated() {
            if let distance = try? featurePrint.distance(to: frame.observation), distance < similarityThreshold {
                // Replace the frame if the new frame has a higher score.
                if newFrame.score > frame.score {
                    topFrames[index] = newFrame
                }
                isSimilar = true
                break
            }

            // Comparing the scores to find the insertion index.
            if newFrame.score > frame.score {
                insertionIndex = index
                break
            }
        }

        // Insert the new frame if it's not similar and
        // has an insertion index within the number of frames to store.
        if !isSimilar && insertionIndex < maxTopFrames {
            topFrames.insert(newFrame, at: insertionIndex)
            if topFrames.count > maxTopFrames {
                topFrames.removeLast()
            }
        }
    }

    return topFrames
}

// MARK: Generate the thumbnails.
/// Generate thumbnails from the top-rated frames.
func generateThumbnails(from topFrames: [Frame], videoURL: URL, with asset: AVURLAsset) async -> [Thumbnail] {
    /// The image generator that generates images from the video.
    let imageGenerator = AVAssetImageGenerator(asset: asset)

    // Apply the orientation of the source when it generates an image.
    imageGenerator.appliesPreferredTrackTransform = true

    /// The thumbnails to generate from the frames.
    var thumbnails: [Thumbnail] = []

    // Create the thumbnail for each frame by extracting the image from the frame.
    for frame in topFrames {
        if let image = await extractImage(from: imageGenerator, at: frame.time) {
            let thumbnail = Thumbnail(image: image, frame: frame)
            thumbnails.append(thumbnail)
        }
    }

    return thumbnails
}

// MARK: Extract the images.
/// Extracts the image from the video and the time of the frame.
func extractImage(from imageGenerator: AVAssetImageGenerator, at time: CMTime) async -> CGImage? {
    do {
        /// The tuple that contains the image and the timestamp of the video.
        let generatedFrame = try await imageGenerator.image(at: time)
        return generatedFrame.image
    } catch {
        print("Error extracting image at time \(time.seconds): \(error.localizedDescription)")
        return nil
    }
}
