/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for storing information a person enters to create a location reminder.
*/

import EventKit

struct LocationReminderEntry: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var radius: Double
    var mappedPriority: Priority
    var mappedProximity: Proximity
    
    init(title: String = "", radius: Double = 0, priority: Priority = .none, proximity: Proximity = .leaving) {
        self.id = UUID().uuidString
        self.title = title
        self.radius = radius
        self.mappedPriority = priority
        self.mappedProximity = proximity
    }
}

extension LocationReminderEntry: Equatable {
    static func == (lhs: LocationReminderEntry, rhs: LocationReminderEntry) -> Bool {
        return lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.radius == rhs.radius &&
        lhs.mappedPriority == rhs.mappedPriority &&
        lhs.mappedProximity == rhs.mappedProximity
    }
}

extension LocationReminderEntry {
    var priority: Int {
        mappedPriority.rawValue
    }
    
    var proximity: EKAlarmProximity {
        mappedProximity.alarmProximity
    }
}
