/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Keeps track of how fast someone is throwing tennis balls.
*/

import Observation

@Observable
@MainActor
final class ThrowSpeedTracker {
    private var speed: Float? = nil
    private var maxSpeed: Float = 0.0
    
    private var isRecordSpeed: Bool {
        speed ?? 0.0 >= maxSpeed
    }
    
    func recordThrow(speed: Float) {
        self.speed = speed
        maxSpeed = max(maxSpeed, speed)
    }
    
    var renderedText: String? {
        guard let speed else {
            return nil
        }
        let congrats = isRecordSpeed ? ". Congrats, that's a new record!" : ""
        return "Ball speed: \(String(format: "%.2f", speed)) m/s" + congrats
    }
}
