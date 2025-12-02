/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for date components.
*/

import SwiftUI

@MainActor
@Observable class DateComponentsModel {
    var dateComponents: DateComponents
    
    var dateComponentsStyle: DateComponentsFormatter.UnitsStyle
    
    var localizedDuration: String {
        DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: dateComponentsStyle) ?? ""
    }
    
    init() {
        self.dateComponents = DateComponents(hour: 2, minute: 15)
        self.dateComponentsStyle = .abbreviated
    }
}
