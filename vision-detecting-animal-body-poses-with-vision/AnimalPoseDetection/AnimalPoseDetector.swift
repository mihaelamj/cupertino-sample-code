/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class containing the Vision part, which creates and performs the request and then returns
    the recognized points from VNAnimalBodyPose observations.
*/

import AVFoundation
import Vision

// The Vision part.
class AnimalPoseDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    // Get the animal body joints using the VNRecognizedPoint.
    @Published var animalBodyParts = [VNAnimalBodyPoseObservation.JointName: VNRecognizedPoint]()
    
    // Notify the delegate that a sample buffer was written.
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Create a new request to recognize an animal body pose.
        let animalBodyPoseRequest = VNDetectAnimalBodyPoseRequest(completionHandler: detectedAnimalPose)
        // Create a new request handler.
        let imageRequestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .right)
        do {
            // Send the request to the request handler with a call to perform.
            try imageRequestHandler.perform([animalBodyPoseRequest])
        } catch {
            print("Unable to perform the request: \(error).")
        }
    }

    func detectedAnimalPose(request: VNRequest, error: Error?) {
        // Get the results from VNAnimalBodyPoseObservations.
        guard let animalBodyPoseResults = request.results as? [VNAnimalBodyPoseObservation] else { return }
        // Get the animal body recognized points for the .all group.
        guard let animalBodyAllParts = try? animalBodyPoseResults.first?.recognizedPoints(.all) else { return }
        self.animalBodyParts = animalBodyAllParts
    }
}
