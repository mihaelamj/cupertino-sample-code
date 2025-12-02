/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Bundles an action label with a confidence value.
 The extension defines and generates placeholder predictions with labels that
 represent when the camera frame is devoid of people or when the model's
 confidence isn't high enough.
*/

/// Bundles an action label with a confidence value.
struct ActionPrediction {
    /// The name of the action the Exercise Classifier predicted.
    let label: String

    /// The Exercise Classifier's confidence in its prediction.
    let confidence: Double!

    /// A string that represents the confidence as percentage if applicable;
    /// otherwise `nil`.
    var confidenceString: String? {
        guard let confidence = confidence else {
            return nil
        }

        // Convert the confidence to a percentage based string.
        let percent = confidence * 100
        let formatString = percent >= 99.5 ? "%2.0f %%" : "%2.1f %%"
        return String(format: formatString, percent)
    }

    init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}

extension ActionPrediction {
    /// Defines placeholder prediction labels beyond the scope of the
    /// action classifier model.
    private enum AppLabel: String {
        case starting = "Starting Up"
        case noPerson = "No Person"
        case lowConfidence = "Low Confidence"
    }

    /// A prediction that represents a time window that doesn't contain
    /// enough human body pose observations.
    static let startingPrediction = ActionPrediction(.starting)

    /// A prediction that represents a time window that doesn't contain
    /// enough human body pose observations.
    static let noPersonPrediction = ActionPrediction(.noPerson)

    /// A prediction that takes the place of real prediction from the
    /// action classifier model that has a low confidence.
    static let lowConfidencePrediction = ActionPrediction(.lowConfidence)

    /// Creates a prediction with an app-defined label.
    /// - Parameter otherLabel: A label defined by the application, not the
    /// action classifier model.
    /// Only the `lowConfidence()` and `noPerson()` type methods use this initializer.
    private init(_ otherLabel: AppLabel) {
        label = otherLabel.rawValue
        confidence = nil
    }

    /// A Boolean that indicates whether the label is from the action classifier model.
    ///
    /// isModelLabel and `isAppLabel` are mutually exclusive.
    var isModelLabel: Bool { !isAppLabel }

    /// A Boolean that indicates whether the label is from the app.
    ///
    /// `isAppLabel` and `isModelLabel` are mutually exclusive.
    var isAppLabel: Bool { confidence == nil }
}
