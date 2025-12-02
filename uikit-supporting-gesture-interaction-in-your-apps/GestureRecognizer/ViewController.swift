/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that handles gesture recognizers.
*/

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var yellowPiece: UILabel!
    @IBOutlet weak var bluePiece: UILabel!
    @IBOutlet weak var pinkPiece: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializePieces()
        /**
         Create and set up a gesture recognizer for resetting the pieces to the initial state.
         Allow delivering touches to the view when ResetGestureRecognizer is recognizing.
         */
        let resetGestureRecognizer = ResetGestureRecognizer(target: self, action: #selector(resetPieces(_:)))
        view.addGestureRecognizer(resetGestureRecognizer)
        
        resetGestureRecognizer.delegate = self

        resetGestureRecognizer.cancelsTouchesInView = false
    }
    
    /**
     Animate the pieces to the initial state after device rotation.
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.initializePieces()
        })
    }
    
    /**
     Set up the initial state for the pieces.
     */
    private func initializePieces() {
        let pieceSize: CGFloat = (min(view.bounds.size.width, view.bounds.height) - 30) / 3
        let pieces: [UIView] = [yellowPiece, bluePiece, pinkPiece]
        pieces.forEach { piece in
            piece.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            piece.transform = .identity
            piece.bounds.size = CGSize(width: pieceSize, height: pieceSize)
        }
        
        let centerX = view.bounds.width / 2.0, centerY = view.bounds.height / 2.0
        bluePiece.center = CGPoint(x: centerX, y: centerY)
        yellowPiece.center = CGPoint(x: centerX - pieceSize, y: centerY - pieceSize)
        pinkPiece.center = CGPoint(x: centerX + pieceSize, y: centerY + pieceSize)
    }
    
    /**
     Scale and rotation transforms are relative to the layer's anchor point.
     To be more intuitive, move the view's anchor point to the location of the gesture,
     which is usually the centroid of the touches involved in the gestures.
     */
    private func adjustAnchor(for gestureRecognizer: UIGestureRecognizer) {
        guard let piece = gestureRecognizer.view, gestureRecognizer.state == .began else {
            return
        }
        let locationInPiece = gestureRecognizer.location(in: piece)
        let locationInSuperview = gestureRecognizer.location(in: piece.superview)
        let anchorX = locationInPiece.x / piece.bounds.size.width
        let anchorY = locationInPiece.y / piece.bounds.size.height
        piece.layer.anchorPoint = CGPoint(x: anchorX, y: anchorY)
        piece.center = locationInSuperview
    }

    /**
     When a user touches down on a piece, bring the piece to the front so that it is fully visible.
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let touchedView = touch.view,
              [yellowPiece, bluePiece, pinkPiece].contains(touchedView) else {
            return
        }
        view.bringSubviewToFront(touchedView)
    }
    
    /**
     Shift the piece's center by the pan amount.
     Reset the gesture recognizer's translation to {0, 0} after applying so the next callback is a delta from the current position.
     */
    @IBAction func panPiece(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard panGestureRecognizer.state == .began || panGestureRecognizer.state == .changed,
              let piece = panGestureRecognizer.view else {
            return
        }
        let translation = panGestureRecognizer.translation(in: piece.superview)
        piece.center = CGPoint(x: piece.center.x + translation.x, y: piece.center.y + translation.y)
        panGestureRecognizer.setTranslation(.zero, in: piece.superview)
    }
    
    /**
     Scale the piece by the current scale.
     Reset the gesture recognizer's scale to 1 after applying so the next callback is a delta from the current scale.
     */
    @IBAction func pinchPiece(_ pinchGestureRecognizer: UIPinchGestureRecognizer) {
        guard pinchGestureRecognizer.state == .began || pinchGestureRecognizer.state == .changed,
              let piece = pinchGestureRecognizer.view else {
            return
        }
        adjustAnchor(for: pinchGestureRecognizer)
        
        let scale = pinchGestureRecognizer.scale
        piece.transform = piece.transform.scaledBy(x: scale, y: scale)
        pinchGestureRecognizer.scale = 1 // Clear scale so that it is the right delta next time.
    }
 
    /**
     Rotate the piece by the current rotation.
     Reset the gesture recognizer's rotation to 0 after applying so the next callback is a delta from the current rotation.
     */
    @IBAction func rotatePiece(_ rotationGestureRecognizer: UIRotationGestureRecognizer) {
        guard rotationGestureRecognizer.state == .began || rotationGestureRecognizer.state == .changed,
              let piece = rotationGestureRecognizer.view else {
            return
        }
        adjustAnchor(for: rotationGestureRecognizer)
        piece.transform = piece.transform.rotated(by: rotationGestureRecognizer.rotation)
        rotationGestureRecognizer.rotation = 0 // Clear rotation so that it is the right delta next time.
    }

    /**
     Animate the pieces to the initial state when detecting the reset gesture.
     */
    @objc
    func resetPieces(_ resetGestureRecognizer: ResetGestureRecognizer) {
        guard resetGestureRecognizer.state == .ended else {
          return
        }
        UIView.animate(withDuration: CATransaction.animationDuration()) {
            self.initializePieces()
        }
    }
    
    /**
     Ensure the the gesture recognizers can all recognize their gestures simultaneously.
     */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    /**
     Avoid delivering the touches occurring on the pieces to ResetGestureRecognizer.
     */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer.isKind(of: ResetGestureRecognizer.self),
              let touchedView = touch.view else {
            return true
        }
        return touchedView == view
    }
}
