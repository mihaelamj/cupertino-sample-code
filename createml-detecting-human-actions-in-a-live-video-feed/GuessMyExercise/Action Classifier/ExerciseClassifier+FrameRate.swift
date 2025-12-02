/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines the Exercise Classifier's frame rate.
 This property reflect the value the model's author set in the
 Create ML developer tool's training parameters.
*/

import CoreML

extension ExerciseClassifier {
    /// The value of the Frame Rate training parameter the action
    /// classifier's creator used in the Create ML developer tool.
    ///
    /// The app configures the device's camera to generate this many frames
    /// per second to match the action classifier's expectations.
    ///
    /// **Note**
    /// If you replace the Exercise Classifier with your own action
    /// classifier model, set this value to match the Frame Rate training
    /// parameter you used in the Create ML developer tool.
    static let frameRate = 30.0

    /// Returns number of input data samples the model expects in its `poses`
    /// multiarray input to make a prediction. See ExerciseClassifier.mlmodel >
    /// Predictions
    ///
    /// The `keypointsMultiArray()` method of a `VNHumanBodyPoseObservation`
    /// returns a multiarray for one sample.
    ///
    /// The window size is the number of samples you must merge together
    /// by using the `MLMultiArray(concatenating: axis: dataType:)` initializer.
    func calculatePredictionWindowSize() -> Int {
        let modelDescription = model.modelDescription

        let modelInputs = modelDescription.inputDescriptionsByName
        assert(modelInputs.count == 1, "The model should have exactly 1 input")

        guard let  input = modelInputs.first?.value else {
            fatalError("The model must have at least 1 input.")
        }

        guard input.type == .multiArray else {
            fatalError("The model's input must be an `MLMultiArray`.")
        }

        guard let multiArrayConstraint = input.multiArrayConstraint else {
            fatalError("The multiarray input must have a constraint.")
        }

        let dimensions = multiArrayConstraint.shape
        guard dimensions.count == 3 else {
            fatalError("The model's input multiarray must be 3 dimensions.")
        }

        let windowSize = Int(truncating: dimensions.first!)
        let frameRate = ExerciseClassifier.frameRate

        let timeSpan = Double(windowSize) / frameRate
        let timeString = String(format: "%0.2f second(s)", timeSpan)
        let fpsString = String(format: "%.0f fps", frameRate)
        print("Window is \(windowSize) frames wide, or \(timeString) at \(fpsString).")

        return windowSize
    }
}
