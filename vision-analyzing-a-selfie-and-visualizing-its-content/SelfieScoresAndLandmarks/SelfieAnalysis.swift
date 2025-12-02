/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the image processing through the Vision framework.
*/

import PhotosUI
import SwiftUI
import Vision

struct Selfie: Hashable {
    var photo: Data
    var score: Float
    var facesDetected: Int {
        return landmarksResults.count
    }
    
    /// The array of `FaceObservation` objects to hold `Vision` results.
    var landmarksResults: [FaceObservation]
}

/// A function that processes a single photo, and returns a new `Selfie` object with the results.
func processSelfie(photo: Data) async throws -> Selfie {
    /// Instantiate the `Vision` requests.
    let detectFacesRequest = DetectFaceRectanglesRequest()
    var qualityRequest = DetectFaceCaptureQualityRequest()
    var landmarksRequest = DetectFaceLandmarksRequest()
    
    /// Perform `DetectFaceRectanglesRequest` to locate all faces in the photo.
    let handler = ImageRequestHandler(photo)
    let faceObservations = try await handler.perform(detectFacesRequest)
    
    /// Set the faces that `DetectFaceLandmarksRequest` and `DetectFaceCaptureQualityRequest` analyze.
    landmarksRequest.inputFaceObservations = faceObservations
    qualityRequest.inputFaceObservations = faceObservations
        
    /// Perform `DetectFaceCaptureQualityRequest` and `DetectFaceLandmarksRequest` on the photo.
    let (qualityResults, landmarksResults) = try await handler.perform(qualityRequest, landmarksRequest)
    
    var score: Float = 0
    /// Set the capture-quality score of the photo if `Vision` detects one face.
    if qualityResults.count == 1 {
        score = qualityResults[0].captureQuality!.score
    /// Set the average capture-quality score if `Vision` detects multiple faces.
    } else if qualityResults.count > 1 {
        for face in qualityResults {
            score += face.captureQuality!.score
        }
        score /= Float(qualityResults.count)
    }
        
    return Selfie(photo: photo, score: score, landmarksResults: landmarksResults)
}

/// Concurrently processes a collection of photos by using the `processSelfie` function and returns a sorted array of `Selfie` objects.
func processAllSelfies(photos: [Data]) async throws -> [Selfie] {
    var selfies = [Selfie]()
    try await withThrowingTaskGroup(of: Selfie.self) { group in
        for photo in photos {
            group.addTask {
                return try await processSelfie(photo: photo)
            }
        }
        
        /// Add the photo to the `selfies` array if `Vision` detects at least one face in the photo.
        for try await selfie in group where selfie.facesDetected > 0 {
            selfies.append(selfie)
        }
    }
    
    /// Sort the selfies in descending order of their capture-quality scores.
    selfies.sort { $0.score > $1.score }
    
    return selfies
}
