/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions for working with RealityKit scenes.
*/

import RealityKit
import SwiftUI

public extension RealityKit.Scene {
    
    /// Get the first entity with a specific component in a scene.
    func first<T>(withComponent: T.Type) -> (entity: Entity, component: T)? where T: Component {
        let entities = performQuery(.init(where: .has(withComponent)))
        for entity in entities {
            if let component = entity.components[T.self] {
                return (entity: entity, component: component)
            }
        }
        return nil
    }
    
    /// A helper function for posting RealityKit notifications to the scene.
    func postRealityKitNotification(notification: String) {
        NotificationCenter.default.post(
            name: Notification.Name("RealityKit.NotificationTrigger"),
            object: nil,
            userInfo: [
                "RealityKit.NotificationTrigger.Scene": self,
                "RealityKit.NotificationTrigger.Identifier": notification
            ])
    }
}
