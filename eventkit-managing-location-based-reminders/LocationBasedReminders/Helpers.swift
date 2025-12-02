/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extends the sequence protocol, and the array, date, and double structures.
*/

import Foundation

extension Array where Element == LocationReminder {
    /// An array of completed location reminders.
    var completed: [LocationReminder] {
        return filter(\.isCompleted)
    }
    
    /// An array of incompleted location reminders.
    var incomplete: [LocationReminder] {
        return filter { !$0.isCompleted }
    }
    
    /// Sorts reminders by creation date, due date, or title in ascending order.
    func reminders(sortedBy sort: ReminderSortValue) -> [LocationReminder] {
        switch sort {
        case .creationDate: return self.sorted(by: \.creationDate)
        case .dueDate: return self.sorted(by: \.dueDate)
        case .title: return self.sorted(by: \.title)
        }
    }
}

extension Date {
    /// The date components of a date occuring seven days from now.
    static var next7DaysComponents: DateComponents {
        let gregorian = Calendar(identifier: .gregorian)
        var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date.now)
        components.day = 7
        return components
    }
    
    /// The date matching the given components.
    static func gregorianDate(from components: DateComponents?) -> Date {
        let gregorian = Calendar(identifier: .gregorian)
        
        guard let components, let date = gregorian.date(from: components) else {
            return Date()
        }
        return date
    }
}

extension Double {
    /// Converts the double value from a unit of length to another unit of length.
    func convert(from unit: UnitLength, to otherUnit: UnitLength) -> Double {
        let measurement = Measurement(value: self, unit: unit)
        return measurement.converted(to: otherUnit).value
    }
    
    /// Returns a formatted string that includes a converted value and a unit of length.
    func displayValueConverted(from unit: UnitLength, to otherUnit: UnitLength) -> String {
        let convertedValue = self.convert(from: unit, to: otherUnit)
        
        let measured = Measurement<UnitLength>(value: convertedValue, unit: otherUnit)
        let formattedValue = measured.formatted(.measurement(width: .wide,
                                                             usage: .asProvided,
                                                             numberFormatStyle: .number.precision(.fractionLength(2))))
        return String(localized: "\(formattedValue)")
    }
}

extension Sequence {
    /// Sorts in ascending order.
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }
}
