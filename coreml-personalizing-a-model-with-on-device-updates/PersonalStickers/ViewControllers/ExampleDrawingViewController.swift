/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View Controller that handles creating a single example to update a model.
*/

import UIKit

final class ExampleDrawingViewController: UIViewController {
    weak var delegate: DrawingDelegate?
    @IBOutlet weak var canvasContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the imageView's tint color to a color that adapts to the interface style.
        imageView.tintColor = UIColor(named: "DrawingTintColor")
    }
    
    @IBSegueAction func makeCanvasViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> DrawingCanvasViewController? {
        guard let canvasViewController = DrawingCanvasViewController(coder: coder) else {
            print("Unable to create CanvasViewController")
            return nil
        }
        canvasViewController.delegate = self
        return canvasViewController
    }
}

extension ExampleDrawingViewController: DrawingDelegate {
    func didProduce(drawing: UserDrawing, sender: Any?) {
        // For the drawing color to adapt to the interface style, use `.alwaysTemplate` rendering mode
        let image = UIImage(cgImage: drawing.image,
                            scale: UIScreen.main.scale,
                            orientation: .up)
            .withRenderingMode(.alwaysTemplate)
        DispatchQueue.main.async {
            self.imageView.image = image
            self.imageView.isHidden = false
            self.canvasContainerView.isHidden = true
            self.label.isHidden = true
        }
        
        delegate?.didProduce(drawing: drawing, sender: self)
    }
}
