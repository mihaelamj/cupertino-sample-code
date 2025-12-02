/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Updatable Drawing Classifier extension with a convenience image constraint property.
*/

import CoreML

/// - Tag: ImageConstraintProperty
extension UpdatableDrawingClassifier {
    /// Returns the image constraint for the model's "drawing" input feature.
    var imageConstraint: MLImageConstraint {
        let description = model.modelDescription
        
        let inputName = "drawing"
        let imageInputDescription = description.inputDescriptionsByName[inputName]!
        
        return imageInputDescription.imageConstraint!
    }
}
