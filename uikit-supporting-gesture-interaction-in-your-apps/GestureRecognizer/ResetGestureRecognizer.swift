/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom gesture recognizer that recognizes any path that has at least three horizontal turnings.
To play with it, put one finger on the area that the colored pieces don't cover, then move the finger
right - left - right - left, or vice versa, like shaking it on the screen.
*/

import UIKit

class ResetGestureRecognizer: UIGestureRecognizer {

    private var trackedTouch: UITouch?
    private var touchedPoints = [CGPoint]()
    
    /**
     ResetGestureRecognizer is a one-touch recognizer, so begins only if touches.count equals to 1.
     
     After this gesture recognizer begins, users can add more touches which trigger this method.
     This gesture recognizer ignores the touches if they are not the tracked one.
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if touches.count != 1 { // Ignore the touches if there are more than one.
            for touch in touches {
                ignore(touch, for: event)
            }
            state = .failed
            return
        }
        /**
         Pick up the first touch if the gesture recognizer isn't tracking any touch yet,
         and ignore the touches if they are not the tracked one without turning state to .failed.
         */
        trackedTouch = trackedTouch ?? touches.first
        if let touch = touches.first, touch != trackedTouch! {
            ignore(touch, for: event)
            return
        }
        state = .began
    }
    
    /**
     Gathering the touched points. Ignore the pending touches if the state has already failed.
     */
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        guard state != .failed else { // Ignore pending touches if the state is already .failed.
            return
        }
        guard let touch = touches.first, let window = view?.window else {
            fatalError("Failed to unwrap `touches.first` and `view?.window`!")
        }
        touchedPoints.append(touch.location(in: window))
        state = .changed
    }
    
    /**
     Check if the touched points fit the custom gesture, and change the state accordingly.
     */
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        let count = countHorizontalTurning(touchedPoints: touchedPoints)
        state = count > 2 ? .ended : .failed
        print("\(state == .ended ? "Recognized" : "Failed"): horizontal turning count = \(count)")
    }
    
    /**
     Clear the touched points and set the state to .possible.
     */
    override func reset() {
        super.reset()
        trackedTouch = nil
        touchedPoints.removeAll()
        state = .possible
    }

    /**
     Cancel the gesture recognizing.
     */
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        state = .cancelled
    }
    
    /**
     Count the horizontal turnings for the touched points and return the number.
     
     This sample determines a horizontal turning by calculating the horizontal distances between every two points and checking their signs.
     If a finger goes right and then turns left (or vice versa), the path will have a turning point. The horizontal distance from the point to its
     previous neighbor must be larger than 0, and from the next neighbor to the point must be smaller than 0.
     
     This sample filters out the points that have a same x value because they can't be a horizontal turning, but doesn't go further to eliminate
     the other noises or check the segment distances in the path. Real apps might consider doing that to improve the gesture recognition
     accuracy and avoid recognizing false positive gestures.
     */
    private func countHorizontalTurning(touchedPoints: [CGPoint]) -> Int {
        var distances = [CGFloat]()
        var turningCount = 0
        /**
         Calculate the horizontal distances between every two points.
         Ignore the points that have a same x value because they can't be a horizontal turning.
         */
        guard !touchedPoints.isEmpty else { return 0 }
        _ = touchedPoints.reduce(touchedPoints[0]) { point1, point2 in
            if point2.x != point1.x {
                distances.append(point2.x - point1.x)
            }
            return point2
        }
        /**
         Determine the horizontal turning points by checking the sign of the neighbor distance values.
         */
        guard !distances.isEmpty else { return 0 }
        _ = distances.reduce(distances[0]) { distance1, distance2 in
            if (distance1 > 0 && distance2 < 0) || (distance1 < 0 && distance2 > 0) {
                turningCount += 1
            }
            return distance2
        }
        return turningCount
    }
}
