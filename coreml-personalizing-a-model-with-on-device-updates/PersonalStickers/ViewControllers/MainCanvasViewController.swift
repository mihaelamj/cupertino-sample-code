/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application's main view controller.
*/

import UIKit

class MainCanvasViewController: UIViewController {
    /// View that displays the stickers once drawn on screen
    @IBOutlet weak var stickerView: UIView!
    
    /// Guides the user through adding a new sticker and updating the model
    @IBAction func addNewSticker() {
        performSegue(withIdentifier: "addNewSticker", sender: self)
    }
    
    /// Resets the model to the original version that can't recognize any drawings
    @IBAction func resetModel() {
        ModelUpdater.resetDrawingClassifier()
        addNewSticker()
    }
    
    // MARK: - Segues
    
    @IBSegueAction func makeCanvasViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> DrawingCanvasViewController? {
        guard let canvasViewController = DrawingCanvasViewController(coder: coder) else {
            print("Unable to create CanvasViewController")
            return nil
        }
        canvasViewController.delegate = self
        return canvasViewController
    }
}

/// Extension that handles receiving drawings from the `CanvasViewController`
extension MainCanvasViewController: DrawingDelegate {
    func checkIfClearing(drawing: UserDrawing) -> Bool {
        // If this drawing intersects with any previous drawings,
        // consider this a clearing drawing and clear the intersecting stickers.
        var isClearing = false
        
        DispatchQueue.main.sync {
            for sticker in stickerView.subviews where drawing.rect.intersects(sticker.frame) {
                sticker.removeFromSuperview()
                isClearing = true
            }
        }
        return isClearing
    }
    
    func didProduce(drawing: UserDrawing, sender: Any?) {
        guard !checkIfClearing(drawing: drawing) else {
            print("User erased some stickers, skipping prediction.")
            return
        }
        
        // Convert the drawing's image into an `MLFeatureValue` of type `.image`.
        let imageFeatureValue = drawing.featureValue
        
        // If classification is enabled, it tries to classify the drawings with the sticker classifier
        let drawingLabel = ModelUpdater.predictLabelFor(imageFeatureValue)
        
        if let lbl = drawingLabel {
          print("Label: \(lbl)")
        }
        
        DispatchQueue.main.async {
            guard let emojiCharacter = drawingLabel else {
                // If the drawing is not recognized, the model hasn't been trained yet.
                // In this case, the Canvas returns an image that can be used as a first example
                self.addNewSticker()
                return
            }
            
            // The drawing classifier recognized the drawing, add an emoji "sticker" to the canvas.
            let sticker = UILabel(frame: drawing.rect)
        
            sticker.text = emojiCharacter
            
            // The max font size that will be rendered
            sticker.font = .systemFont(ofSize: 200)
            sticker.numberOfLines = 1
            sticker.baselineAdjustment = .alignCenters
            sticker.textAlignment = .center
            sticker.adjustsFontSizeToFitWidth = true
            self.stickerView.addSubview(sticker)
        }
    }
}
