/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extends the reminder class.
*/

import EventKit
import MapKit

extension EKReminder {
    /// The completion date of a reminder.
    var dueDate: Date {
        return Date.gregorianDate(from: dueDateComponents)
    }
    
    /// Specifies whether the reminder is location-based.
    var isLocation: Bool {
        guard let alarms else { return false }
        
        let proximityAlarms = alarms.filter {
            $0.structuredLocation != nil && ($0.proximity == .enter || $0.proximity == .leave)
        }
        
        return !proximityAlarms.isEmpty
    }
    
    /// Structured location of the first alarm found.
    var geofence: EKStructuredLocation? {
        guard let alarm = alarms?.first(where: { $0.structuredLocation != nil }),
              let structuredLocation = alarm.structuredLocation else {
            return nil
        }
        return structuredLocation
    }
    
    /// The proximity of the first alarm found.
    var alarmProximity: EKAlarmProximity {
        guard let alarm = alarms?.first(where: { $0.structuredLocation != nil }) else {
            return .none
        }
        return alarm.proximity
    }
}
