/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The relative date-time formatter data model.
*/

import SwiftUI

@MainActor
@Observable class RelativeDateTimeFormatterModel {
    var formatter: RelativeDateTimeFormatter
    var unitsStyle: RelativeDateTimeFormatter.UnitsStyle { didSet { updateFormatter() } }
    
    var dateTimeStyle: RelativeDateTimeFormatter.DateTimeStyle { didSet { updateFormatter() } }
    
    var dayBeforeYesterday: String {
        string(from: DateComponents(day: -2))
    }
    
    var yesterday: String {
        string(from: DateComponents(day: -1))
    }
      
    var someTimeAgo: String {
        string(from: DateComponents(minute: -37))
    }
    
    var threeHoursLater: String {
        string(from: DateComponents(hour: 3))
    }
    
    var tomorrow: String {
        string(from: DateComponents(day: 1))
    }
    
    var dayAfterTomorrow: String {
        string(from: DateComponents(day: 2))
    }
   
    init() {
        self.formatter = RelativeDateTimeFormatter()
        self.unitsStyle = .short
        self.dateTimeStyle = .named
        self.updateFormatter()
    }
    
    private func string(from dateComponents: DateComponents) -> String {
        return formatter.localizedString(from: dateComponents)
    }
    
    private func updateFormatter() {
        formatter.dateTimeStyle = dateTimeStyle
        formatter.unitsStyle = unitsStyle
    }
}
