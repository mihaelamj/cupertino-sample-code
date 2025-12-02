/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for dates.
*/

import SwiftUI

struct DatesView: View {
    @State private var dateFormatterModel = DateFormatterModel()
    @State private var dateComponentsModel = DateComponentsModel()
    @State private var dateIntervalModel = DateIntervalFormatterModel()
    @State private var relativeDateTimeModel = RelativeDateTimeFormatterModel()
    
    var body: some View {
        ScrollView {
            VStack {
                HeaderImage(name: "clock")
                DateFormatterView(model: dateFormatterModel)
                DateComponentsFormatterView(model: dateComponentsModel)
                DateIntervalFormatterView(model: dateIntervalModel)
                RelativeDateTimeFormatterView(model: relativeDateTimeModel)
            }
        }
    }
}

#Preview {
    DatesView()
}
