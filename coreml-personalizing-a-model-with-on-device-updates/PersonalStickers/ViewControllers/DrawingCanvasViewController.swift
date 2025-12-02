/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Bridging class that allows the use of a `PKCanvasView` in SwiftUI.
*/

import UIKit
import PencilKit

/// Protocol describing how other view controllers can receive drawings
protocol DrawingDelegate: AnyObject {
    func didProduce(drawing: UserDrawing, sender: Any?)
}

final class DrawingCanvasViewController: UIViewController, PKCanvasViewDelegate {
    weak var delegate: DrawingDelegate?
    
    /// Work item used to submit the drawing after a delay, in order to allow for drawings with multiple strokes
    var submitWorkItem: DispatchWorkItem?
    
    @IBOutlet weak var canvasView: PKCanvasView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCanvasView()
    }
    
    /// Configures the `PKCanvasView`
    func configureCanvasView() {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 20)
        canvasView.delegate = self
        canvasView.allowsFingerDrawing = true
    }
    
    // MARK: - PKCanvasViewDelegate
    
    /// Callback invoked when a user begins using a tool
    ///
    /// This happens when a user begins to draw a new stroke
    /// - Parameter canvasView: The `CanvasView` instance used for drawing.
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        // Cancel the submission of the previous drawing when a user begins drawing
        // This lets the user draw another stroke without a time limit of 0.5 seconds
        submitWorkItem?.cancel()
    }
    
    /// Callback invoked when the canvasView's drawing has changed.
    ///
    /// This can occur in 1 of 2 situations:
    /// - The drawing was cleared or reset
    /// - New strokes have been added to the drawing
    ///
    /// - Parameter canvasView: The `CanvasView` instance used for drawing.
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        let drawingRect = canvasView.drawing.bounds
        guard drawingRect.size != .zero else {
            return
        }
        
        // Check if the user is crossing out previous stickers
        let intersectingViews = canvasView.subviews
            .compactMap { $0 as? UILabel }
            .filter { $0.frame.intersects(drawingRect) }
        guard intersectingViews.isEmpty else {
            // If the current drawing intersects with existing stickers,
            // remove those stickers
            intersectingViews.forEach { $0.removeFromSuperview() }
            canvasView.drawing = PKDrawing()
            return
        }
        
        // Add a delay before submitting so the user can draw more strokes in this drawing
        // Create a `DispatchWorkItem` to submit the drawing after a delay
        submitWorkItem = DispatchWorkItem { self.submitDrawing(canvasView: canvasView) }
        
        // Schedule the submission 0.5 second from now
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5, execute: submitWorkItem!)
    }
    
    /// Submits the given drawing for further actions.
    ///
    /// Either the drawing is rendered into an image and updated in the View,
    /// or the drawing is classified and the corresponding sticker is added to the canvas.
    /// - Parameter canvasView: The `CanvasView` used for drawing.
    func submitDrawing(canvasView: PKCanvasView) {
        // Get the rectangle containing the drawing
        let drawingRect = canvasView.drawing.bounds.containingSquare
        // Turn the drawing into an image
        // Because this image may be displayed at a larger scale in the training view,
        // a scale of 2.0 is used for smooth rendering.
        let image = canvasView.drawing.image(from: drawingRect, scale: UIScreen.main.scale * 2.0)
        // Store the white tinted version and the rectangle in a drawing object
        let drawing = UserDrawing(image: image.cgImage!, rect: drawingRect)
        
        self.delegate?.didProduce(drawing: drawing, sender: self)
        
        DispatchQueue.main.async {
            canvasView.drawing = PKDrawing()
        }
    }
}

/// Extension to `CGRect` that provides an easy way to calculate a rectangle's containing square
extension CGRect {
    /// The square that contains this rectangle with the centers being equal
    var containingSquare: CGRect {
        // Get the largest dimension
        let dimension = max(size.width, size.height)
        // Adjust each dimension accordingly
        // Note: One of these 2 insets is 0 because it corresponds to the largest dimension
        let xInset = (size.width - dimension) / 2
        let yInset = (size.height - dimension) / 2
        // Perform the inset to get the square
        return insetBy(dx: xInset, dy: yInset)
    }
}
