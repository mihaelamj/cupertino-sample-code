/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The drawing gesture recognizer for implementing Apple Pencil drawing.
*/

import UIKit

/// Use a long-press gesture recognizer for drawing.
/// The pan gesture recognizer begins after moving a few points.
/// - Tag: DrawGestureRecognizer
class DrawGestureRecognizer: UILongPressGestureRecognizer {
    
    weak var currentTouch: UITouch?
    weak var currentEvent: UIEvent?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        currentTouch = touches.first
        currentEvent = event
    }
    
    override func reset() {
        super.reset()
        currentTouch = nil
        currentEvent = nil
    }
}
