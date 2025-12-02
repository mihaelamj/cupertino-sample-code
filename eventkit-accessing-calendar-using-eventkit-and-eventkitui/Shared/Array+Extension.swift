/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extends the array class.
*/
import EventKit

extension Array {
    /// An array of events sorted by start date in ascending order.
    func sortedEventByAscendingDate() -> [EKEvent] {
        guard let self = self as? [EKEvent] else { return [] }
        
        return self.sorted(by: { (first: EKEvent, second: EKEvent) in
            return first.compareStartDate(with: second) == .orderedAscending
        })
    }
}
