/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions for working with scene update context.
*/

import RealityKit

extension SceneUpdateContext {
    
    /// Get the first entity with a specific component in the scene update context.
    @MainActor
    public func first<T> (withComponent: T.Type) -> (entity: Entity, component: T)? where T: Component {
        let entities = entities(matching: .init(where: .has(withComponent)), updatingSystemWhen: .rendering)
        for entity in entities {
            if let component = entity.components[T.self] {
                return (entity: entity, component: component)
            }
        }
        return nil
    }
}
