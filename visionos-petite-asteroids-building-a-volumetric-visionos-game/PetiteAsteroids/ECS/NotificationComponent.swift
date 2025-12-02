/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that passes notifications from the notification center to entity-component-system code.
*/

import RealityKit

struct NotificationComponent: Component, Codable, Sendable {
    
    /// The name of the notification.
    var name: String
}
