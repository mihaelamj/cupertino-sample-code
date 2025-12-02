/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for storing information to display a geofence for a reminder.
*/

import EventKit
import SwiftUI

struct Geofence: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let radius: CLLocationDistance
    let priority: Priority
    let proximity: Proximity
    
    init(title: String, radius: CLLocationDistance, priority: Priority, proximity: Proximity) {
        self.id = UUID().uuidString
        self.title = title
        self.radius = radius
        self.priority = priority
        self.proximity = proximity
    }
}

extension Geofence: Equatable {
    static func == (lhs: Geofence, rhs: Geofence) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.radius == rhs.radius &&
        lhs.priority == rhs.priority &&
        lhs.proximity == rhs.proximity
    }
}

extension Geofence {
    init(reminder: EKReminder) {
        self.init(title: reminder.geofence?.title ?? "Unknown Location",
                  radius: reminder.geofence?.radius ?? 0.0,
                  priority: Priority.matching(reminder.priority),
                  proximity: Proximity.matching(reminder.alarmProximity))
    }
}
