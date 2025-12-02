/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience extension to handle an ARSession.
*/

import UIKit
import ARKit
import Vision

extension ViewController {
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        infoLabel.text = "ARKit Error:\(error.localizedDescription)"
    }

    func sessionWasInterrupted(_ session: ARSession) {
        infoLabel.text = "ARKit session was interrupted"
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }

    // MARK: - ARSessionDelegate

    /// Method called when the ARSession produces a new frame
    ///
    /// - parameter frame: The ARFrame containing information about the last
    ///                    captured video frame and the state of the world
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // When rate-limiting predicitons, skip frames to predict every x
        if shouldSkipFrame > 0 {
            shouldSkipFrame = (shouldSkipFrame + 1) % predictEvery
        }

        predictionQueue.async {
            /// - Tag: MappingOrientation
            // The frame is always oriented based on the camera sensor,
            // so in most cases Vision needs to rotate it for the model to work as expected.
            let orientation = UIDevice.current.orientation

            // The image captured by the camera
            let image = frame.capturedImage

            let imageOrientation: CGImagePropertyOrientation
            switch orientation {
            case .portrait:
                imageOrientation = .right
            case .portraitUpsideDown:
                imageOrientation = .left
            case .landscapeLeft:
                imageOrientation = .up
            case .landscapeRight:
                imageOrientation = .down
            case .unknown:
                print("The device orientation is unknown, the predictions may be affected")
                fallthrough
            default:
                // By default keep the last orientation
                // This applies for faceUp and faceDown
                imageOrientation = self.lastOrientation
            }

            // For object detection, keeping track of the image buffer size
            // to know how to draw bounding boxes based on relative values.
            if self.bufferSize == nil || self.lastOrientation != imageOrientation {
                self.lastOrientation = imageOrientation
                let pixelBufferWidth = CVPixelBufferGetWidth(image)
                let pixelBufferHeight = CVPixelBufferGetHeight(image)
                if [.up, .down].contains(imageOrientation) {
                    self.bufferSize = CGSize(width: pixelBufferWidth,
                                             height: pixelBufferHeight)
                } else {
                    self.bufferSize = CGSize(width: pixelBufferHeight,
                                             height: pixelBufferWidth)
                }
            }


            /// - Tag: PassingFramesToVision

            // Invoke a VNRequestHandler with that image
            let handler = VNImageRequestHandler(cvPixelBuffer: image, orientation: imageOrientation, options: [:])

            do {
                try handler.perform([self.diceDetectionRequest])
            } catch {
                print("CoreML request failed with error: \(error.localizedDescription)")
            }

        }
    }
}
