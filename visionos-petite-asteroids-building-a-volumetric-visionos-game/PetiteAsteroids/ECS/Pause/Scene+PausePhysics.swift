/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions for pausing and playing the physics simulation components in a scene by setting their clock rates.
*/

import RealityKit
import CoreMedia

extension Scene {
    func setPhysicsSimulationRate(_ simulationRate: Float64) {
        for physicsSimulationEntity in self.performQuery(.init(where: .has(PhysicsSimulationComponent.self))) {
            guard let clock = physicsSimulationEntity.components[PhysicsSimulationComponent.self]?.clock else {
                continue
            }

            // Ensure that the clock is of type `CMTimebase` before force casting it to `CMTimebase`.
            if CFGetTypeID(clock) == CMTimebaseGetTypeID() {
                let physicsTimebase = clock as! CMTimebase
                CMTimebaseSetRate(physicsTimebase, rate: simulationRate)
            }
            
            physicsSimulationEntity.components[PhysicsSimulationComponent.self]?.clock = clock
        }
    }
    
    func pausePhysicsSimulation() {
        self.setPhysicsSimulationRate(0)
    }
    
    func playPhysicsSimulation() {
        self.setPhysicsSimulationRate(1)
    }
}
