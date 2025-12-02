/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Various helper functions for working with entities.
*/

import RealityKit
import Foundation
import SwiftUI
import OSLog
import RealityKitContent

let logger = Logger(subsystem: "rk-utilities", category: "general")
extension Entity {
    
    /// Iterate through each descendant of this entity.
    public func forEachDescendant(_ closure: (Entity) -> Void) {
        for child in children {
            closure(child)
            child.forEachDescendant(closure)
        }
    }
    
    /// A recursive search of all descendants with a specific component.
    public func forEachDescendant<T: Component>(withComponent componentClass: T.Type, _ closure: (Entity, T) -> Void) {
        for descendant in children {
            
            // Run the closure using the subentity and its component as parameters.
            if let component = descendant.components[componentClass] {
                closure(descendant, component)
            }
            
            // Call this same function for each descendant entity.
            descendant.forEachDescendant(withComponent: componentClass, closure)
        }
    }
    
    /// Get the first entity with a specific component type that's a descendant of this entity.
    public func first<T: Component>(withComponent componentClass: T.Type) -> (entity: Entity, component: T)? {
        if let component = components[T.self] {
            return (self, component)
        }
        for child in children {
            guard let childPair = child.first(withComponent: componentClass) else {
                continue
            }
            return childPair
        }
        return nil
    }
    
    /// Get the first root entity with a specific component.
    public func firstParent<T: Component>(withComponent componentClass: T.Type) -> (entity: Entity, component: T)? {
        if let component = self.components[T.self] {
            return (self, component)
        }
        if let parent = self.parent {
            return parent.firstParent(withComponent: componentClass)
        }
        return nil
    }

    public func createCompoundCollision(isStatic: Bool, deleteModel: Bool) async -> (collisionRoot: Entity, component: CollisionComponent) {
        return await self.createCompoundCollision(startFromDescendentNamed: nil, isStatic: isStatic, deleteModel: deleteModel)
    }
    public func createCompoundCollision(startFromDescendentNamed: String?,
                                        isStatic: Bool,
                                        deleteModel: Bool) async -> (collisionRoot: Entity, component: CollisionComponent) {
        let entity: Entity? = if let startFromDescendentNamed {
            self.findEntity(named: startFromDescendentNamed)
        } else {
            nil
        }
        
        return await self.createCompoundCollision(startFromDescendent: entity, isStatic: isStatic, deleteModel: deleteModel)
    }
    
    // DFS for all model components that descend from this entity,
    // then use their meshes to generate an array of shape resources to create a collision component for this entity.
    public func createCompoundCollision(startFromDescendent: Entity?,
                                        isStatic: Bool,
                                        deleteModel: Bool) async -> (collisionRoot: Entity, component: CollisionComponent) {
        var collisionRoot: Entity = self
        if let startFromDescendent {
            collisionRoot = startFromDescendent
        }
        
        var shapes: [ShapeResource] = .init()
        // Retain relevant collision-component configurations that the developer sets.
        var collisionMode: CollisionComponent.Mode = .default
        if let collision = collisionRoot.components[CollisionComponent.self] {
            shapes.append(contentsOf: collision.shapes)
            collisionMode = collision.mode
        }
        var meshes = [(entity: Entity, mesh: MeshResource)]()
        collisionRoot.forEachDescendant(withComponent: ModelComponent.self) {
            (entity, modelComponent) in
            
            // Skip descendant entities that you don't want to become part of the collision shape.
            guard entity.components.has(IgnoreCompoundCollisionMarkerComponent.self) == false else { return }
            
            meshes.append((entity: entity, mesh: modelComponent.mesh))
            
            // Optionally, delete the source model component if you're no longer using it.
            if deleteModel {
                entity.components.remove(ModelComponent.self)
            }
        }
        for (entity, mesh) in meshes {
            // Generate the shape from the mesh data.
            guard var shape = if isStatic {
                try? await ShapeResource.generateStaticMesh(from: mesh)
            } else {
                try? await ShapeResource.generateConvex(from: mesh)
            } else {
                continue
            }
            
            // Offset the shape by its translation and orientation relative to the collision root.
            shape = shape.offsetBy(rotation: entity.orientation(relativeTo: collisionRoot), translation: entity.position(relativeTo: collisionRoot))
            shapes.append(shape)
        }
        let collision = CollisionComponent(shapes: shapes, mode: collisionMode)
        collisionRoot.components.set(collision)
        return (collisionRoot, collision)
    }
    
    public func applyCollisionFilterRecursively(filter: CollisionFilter) {
        // Set the group of the entity's collision component, if it has one.
        self.components[CollisionComponent.self]?.filter = filter
        // Apply the collision group recursively to all of the entity's descendants.
        for child in self.children {
            child.applyCollisionFilterRecursively(filter: filter)
        }
    }
    
    func playAnimation(name: String) -> AnimationPlaybackController? {
        guard let (animationEntity, animationLibrary) = self.firstParent(withComponent: AnimationLibraryComponent.self) else {
            return nil
        }
        
        // Find the animation in `AnimationLibrary`, which has keys that Reality Composer Pro generates.
        var resource: AnimationResource? = nil
        for anim in animationLibrary.animations {
            // Look for animations with keys that exactly match the desired name.
            if let last = anim.key.split(separator: "/").last, String(last) == name {
                resource = animationLibrary.animations[anim.key]
                break
            }
        }
        
        // When the expected animation resource isn't available, print a helpful error message.
        guard let resource = resource else {
            logger.error("no animation for \(name)")
            logger.info("printing available animations (\(animationLibrary.animations.count)): ")
            for anim in animationLibrary.animations {
                logger.info("key: \(anim.key)")
            }
            return nil
        }
        
        return animationEntity.playAnimation(resource)
    }
}

