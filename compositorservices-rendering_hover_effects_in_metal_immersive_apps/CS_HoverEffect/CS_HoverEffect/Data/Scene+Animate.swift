/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on `Scene` that contains functions related to animating the 3D chunks.
*/

import Foundation
import QuartzCore

extension Scene {
    
    func expand() {
        drawCalls = drawCalls.map { old in
            var drawcall = old
            drawcall.animationState = .expanding(progress: 0)
            return drawcall
        }
    }
    
    func animate(deltaTime: TimeInterval) {

        animationTime += deltaTime

        // Start expanding.
        if !hasExpanded && animationTime >= 3.0 {
            hasExpanded = true
            expand()
        }

        drawCalls = drawCalls.map { old in
            var drawcall = old
            drawcall.animationState.animate(deltaTime: deltaTime)
            return drawcall
        }
    }
    
    /// Performs animation to collapse the partially immersive view for one draw call.
    /// - Parameter drawcallIndex: The index of the draw call to collapse.
    func collapse(drawcallIndex: Int) {
        drawCalls[drawcallIndex].animationState = .contracting(progress: 0.0)
    }
}
