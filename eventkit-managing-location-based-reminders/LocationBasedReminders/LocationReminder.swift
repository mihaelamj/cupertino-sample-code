/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for a location reminder.
*/

import EventKit
import SwiftUI

struct LocationReminder: Identifiable, Hashable, Sendable {
    let id: String
    let calendarIdentifer: String
    let title: String
    let creationDate: Date
    let dueDate: Date
    let calendarColor: Color
    let geofence: Geofence
    let isCompleted: Bool
    
    init(calendarIdentifer: String,
         title: String, creationDate: Date, dueDate: Date, calendarColor: Color, geofence: Geofence, isCompleted: Bool = false) {
        self.id = UUID().uuidString
        self.calendarIdentifer = calendarIdentifer
        self.title = title
        self.creationDate = creationDate
        self.dueDate = dueDate
        self.calendarColor = calendarColor
        self.geofence = geofence
        self.isCompleted = isCompleted
    }
}

extension LocationReminder: Equatable {
    static func == (lhs: LocationReminder, rhs: LocationReminder) -> Bool {
        return lhs.id == rhs.id &&
        lhs.calendarIdentifer == rhs.calendarIdentifer &&
        lhs.title == rhs.title &&
        lhs.creationDate == rhs.creationDate &&
        lhs.dueDate == rhs.dueDate &&
        lhs.calendarColor == rhs.calendarColor &&
        lhs.geofence == rhs.geofence &&
        lhs.isCompleted == rhs.isCompleted
    }
}

extension LocationReminder {
    init(reminder: EKReminder) {
        self.init(calendarIdentifer: reminder.calendarItemIdentifier,
                  title: reminder.title,
                  creationDate: reminder.creationDate ?? Date(),
                  dueDate: reminder.dueDate,
                  calendarColor: Color(reminder.calendar.cgColor),
                  geofence: Geofence(reminder: reminder),
                  isCompleted: reminder.isCompleted)
    }
    
    var image: String {
        isCompleted ? "checkmark.circle.fill" : "circle"
    }
    
    /*
        EventKit returns the value of the radius property in meters. The app converts
        this value from meters to the person's preferred length unit on the device
        before presenting it in its UI.
    */
    var radiusAsText: String {
        // Get the person's preferred length unit.
        let preferredUnit = UnitLength(forLocale: .current, usage: .asProvided)
        return geofence.radius.displayValueConverted(from: .meters, to: preferredUnit)
    }
    
    var geofenceAsText: String {
        if geofence.radius > 0 {
            return String(localized: "\(geofence.proximity.title) within \(radiusAsText) of \(geofence.title)")
        } else {
            return String(localized: "\(geofence.proximity.title): \(geofence.title)")
        }
    }
}
