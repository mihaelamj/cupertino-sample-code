/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that tracks in-progress processes with a counter.
*/

import RealityKit

struct LoadingTrackerComponent: Component {
    
    private var hasStartedLoading: Bool = false
    private var numInProgress: Int = 0
    
    public mutating func reset() {
        guard isComplete() else { return }
        hasStartedLoading = false
        numInProgress = 0
    }
    
    public mutating func incrementNumInProgress() {
        hasStartedLoading = true
        numInProgress += 1
    }
    
    public mutating func decrementNumInProgress() {
        numInProgress = max(numInProgress - 1, 0)
    }
    
    public func isComplete() -> Bool {
        return hasStartedLoading && numInProgress == 0
    }
}
