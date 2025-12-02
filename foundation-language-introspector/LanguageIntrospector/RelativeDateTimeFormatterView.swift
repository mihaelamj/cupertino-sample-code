/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The relative date-time formatter view.
*/

import SwiftUI

struct RelativeDateTimeFormatterView: View {
    @Bindable var model: RelativeDateTimeFormatterModel
    
    var body: some View {
        VStack {
            HStack {
                Text("तुलनात्‍मक", comment: "Relative")
                    .paddedSubheadlineTextFormat()
                Spacer()
            }
            
            VStack {
                Group {
                    Text(model.dayBeforeYesterday)
                    Text(model.yesterday)
                    Text(model.someTimeAgo)
                    Text(model.threeHoursLater)
                    Text(model.tomorrow)
                    Text(model.dayAfterTomorrow)
                }
                .font(.title3)
                .padding(.top, 5)
                .padding(.bottom, 5)
                
                HStack {
                    Picker("", selection: $model.dateTimeStyle) {
                        Text("स्वाभाविक", comment: "Natural").tag(RelativeDateTimeFormatter.DateTimeStyle.named)
                        Text("संख्या", comment: "Numeric").tag(RelativeDateTimeFormatter.DateTimeStyle.numeric)
                    }
                    .pickerStyle(.segmented)
                }
                HStack {
                    Picker("", selection: $model.unitsStyle) {
                        Text(verbatim: "•").tag(RelativeDateTimeFormatter.UnitsStyle.abbreviated)
                        Text(verbatim: "••").tag(RelativeDateTimeFormatter.UnitsStyle.short)
                        Text(verbatim: "•••").tag(RelativeDateTimeFormatter.UnitsStyle.full)
                        Text(verbatim: "••••").tag(RelativeDateTimeFormatter.UnitsStyle.spellOut)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .opaqueBackground()
        }
    }
}
