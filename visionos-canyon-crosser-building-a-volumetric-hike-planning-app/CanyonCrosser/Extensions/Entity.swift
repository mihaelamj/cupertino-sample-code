/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on `Entity`.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension Entity {
    /// Performs an animation to fade in the entities over the duration.
    /// - Parameters:
    ///   - entities: The entities to fade out.
    ///   - duration: The duration of the animation.
    static func animateIn(entities: [Entity], duration: TimeInterval) {
        entities.forEach { entity in
            entity.components.set(OpacityComponent(opacity: 0.0))
            entity.isEnabled = true
        }

        Entity.animate(.easeIn(duration: duration)) {
            entities.forEach { entity in
                entity.components.set(OpacityComponent(opacity: 1.0))
            }
        }
    }

    /// Performs an animation to fade out the entities over the duration.
    /// - Parameters:
    ///   - entities: The entities to fade out.
    ///   - duration: The duration of the animation.
    static func animateOut(entities: [Entity], duration: TimeInterval) {
        entities.forEach { entity in
            entity.components.set(OpacityComponent(opacity: 1.0))
        }

        Entity.animate(.easeOut(duration: duration)) {
            entities.forEach { entity in
                entity.components.set(OpacityComponent(opacity: 0.0))
            }
        } completion: {
            entities.forEach { entity in
                entity.isEnabled = false
            }
        }
    }

    /// Performs a closure on all entities that have a given component.
    /// - Parameters:
    ///   - componentClass: The class of the component to search for.
    ///   - closure: The closure to perform on each entity.
    public func forEachDescendant<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void) {
        for child in children {
            if let component = child.components[componentClass] {
                closure(child, component)
            }
            child.forEachDescendant(withComponent: componentClass, closure)
        }
    }
    
    /// Returns the first parent entity that has the given component.
    /// - Parameter component: The component to search for.
    func parent(with component: Component.Type) -> Entity? {
        guard let parent else { return nil }
        
        if parent.components[component] != nil {
            return parent
        }
        
        return parent.parent(with: component)
    }
    
    /// Returns the first child entity with the given name.
    /// - Parameter name: The name of the child entity to search for.
    func child(named name: EntityName) -> Entity? {
        children.first(where: { $0.name == name.rawValue })
    }
    
    /// Returns the first child entity with the given name.
    /// - Parameters:
    ///   - name: The name of the child entity to search for.
    ///   - error: The error to throw if the entity is not found.
    func findAndLoadEntity(named name: EntityName, error: LoadingError) async throws -> Entity {
        async let loadedEntity = self.findEntity(named: name.rawValue)

        if let entity = await loadedEntity {
           return entity
        } else {
            throw error
        }
    }
    
    /// Returns the first child entity at the given path.
    /// - Parameter path: The path to the child entity to search for.
    func childAt(path: String) -> Entity? {
        let components = path.components(separatedBy: "/")

        guard let initial = components.first else {
            print("initial is nil in path \(path)")
            return nil
        }

        let initialEntity = children.first(where: { $0.name == initial })
        if components.count > 1 {
            return initialEntity?.childAt(path: components[1...].joined(separator: "/"))
        }
        
        return initialEntity
    }
    
    /// Performs a tree traversal of the entity hierarchy, printing out the names of each entity.
    /// - Parameter indentCount: The number of spaces to indent each level of the hierarchy. Defaults to `0`.
    func printTree(indentCount: Int = 0) {
        let indent = String(repeating: " ", count: indentCount)
        print("\(indent)'\(self.name)'")

        for child in children {
            child.printTree(indentCount: indentCount + 1)
        }
    }
    
    /// Returns the path of the entity in the hierarchy.
    func path() -> String {
        var path = ""
        if let parent {
            path += parent.path() + "/"
        }
        
        path += name
        return path
    }
}
