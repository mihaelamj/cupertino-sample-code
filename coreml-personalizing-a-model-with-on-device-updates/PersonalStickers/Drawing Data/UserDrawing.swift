/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The user's drawing, stored as an image, and its location on a PKCanvasView.
*/

import CoreML
import CoreImage

/// Convenience structure that stores a drawing's `CGImage`
/// along with the `CGRect` in which it was drawn on the `PKCanvasView`
/// - Tag: Drawing
struct UserDrawing {
    private static let ciContext = CIContext()
    
    /// The underlying image of the drawing.
    let image: CGImage
    
    /// Rectangle containing this drawing in the canvas view
    let rect: CGRect
    
    /// Wraps the underlying image in a feature value.
    /// - Tag: ImageFeatureValue
    var featureValue: MLFeatureValue {
        // Get the model's image constraints.
        let imageConstraint = ModelUpdater.imageConstraint
        
        // Get a white tinted version to use for the model
        let preparedImage = whiteTintedImage
        
        let imageFeatureValue = try? MLFeatureValue(cgImage: preparedImage,
                                                    constraint: imageConstraint)
        return imageFeatureValue!
    }
    
    private var whiteTintedImage: CGImage {
        let ciContext = UserDrawing.ciContext
        
        let parameters = [kCIInputBrightnessKey: 1.0]
        let ciImage = CIImage(cgImage: image).applyingFilter("CIColorControls",
                                                             parameters: parameters)
        return ciContext.createCGImage(ciImage, from: ciImage.extent)!
    }
}
