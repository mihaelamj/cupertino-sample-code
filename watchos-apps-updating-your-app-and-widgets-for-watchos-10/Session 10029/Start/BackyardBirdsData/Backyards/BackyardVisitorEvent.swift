/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The backyard visitor event.
*/

import Foundation
import Observation
import SwiftData

@Model public final class BackyardVisitorEvent {
    @Attribute(.unique) public var id: UUID
    public var backyard: Backyard!
    public var bird: Bird!
    public var startDate: Date
    public var endDate: Date
    public var duration: TimeInterval
    
    @Transient public var dateRange: Range<Date> {
        startDate ..< endDate
    }
    
    public init(id: UUID = UUID(), startDate: Date, duration: TimeInterval) {
        self.id = id
        self.startDate = startDate
        self.duration = duration
        self.endDate = startDate.addingTimeInterval(duration)
    }
}

