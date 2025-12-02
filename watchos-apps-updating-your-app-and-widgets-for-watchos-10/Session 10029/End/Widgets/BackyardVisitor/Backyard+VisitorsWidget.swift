/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Backyard extension for BackyardVisitorsWidget.
*/

import Foundation
import OSLog
import SwiftData
import BackyardBirdsData
import SwiftUI

extension Backyard {
    
    public var backgroundColor: Color {
        return self.colorData.skyGradientFlat.color
    }

    public func visitorEventForDate(date: Date) -> BackyardVisitorEvent? {
        guard let event = visitorEvents.first(where: { $0.dateRange.contains(date) }) else {
            return nil
        }
        return event
    }

    public static func anyBackyard(modelContext: ModelContext) -> Backyard {
        return try! modelContext.fetch(FetchDescriptor<Backyard>(sortBy: [.init(\.creationDate)])).first!
    }

    public static func backyardForID(modelContext: ModelContext, backyardID: String) -> Backyard? {
        let backyards = try! modelContext.fetch(FetchDescriptor<Backyard>(sortBy: [.init(\.creationDate)]))
        return backyards.first(where: {
            return $0.id.uuidString == backyardID
        })
    }
    
    public static func allBackyards(modelContext: ModelContext) -> [Backyard] {
        return try! modelContext.fetch(FetchDescriptor<Backyard>(sortBy: [.init(\.creationDate)]))
    }
}

public let remainingHoursFormatter: Duration.UnitsFormatStyle = Duration.UnitsFormatStyle(allowedUnits: [.hours], width: .condensedAbbreviated)
