/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Updatable Drawing Classifier extension with a convenience prediction method.
*/

import CoreML

extension UpdatableDrawingClassifier {
    static let unknownLabel = "unknown"
    
    /// Predicts a label for the given drawing.
    /// - Parameter value: A user's drawing represented as a feature value.
    /// - Returns: The predicted string label, if known; otherwise `nil`.
    func predictLabelFor(_ value: MLFeatureValue) -> String? {
        // Get the image from the feature value as a `CVPixelBuffer`.
        guard let pixelBuffer = value.imageBufferValue else {
            fatalError("Could not extract CVPixelBuffer from the image feature value")
        }
        
        // Use the Drawing Classifier to predict a label for the drawing.
        guard let prediction = try? prediction(drawing: pixelBuffer).label else {
            return nil
        }
        
        // A label of "unknown" means the model has no prediction for the image.
        // This typically means the Drawing Classifier hasn't been updated with any image/label pairs.
        guard prediction != UpdatableDrawingClassifier.unknownLabel else {
            return nil
        }
        
        return prediction
    }
}
