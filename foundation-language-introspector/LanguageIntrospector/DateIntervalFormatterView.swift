/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The date interval formatter view.
*/

import SwiftUI

struct DateIntervalFormatterView: View {
    @Bindable var model: DateIntervalFormatterModel
    
    var body: some View {
        VStack {
            HStack {
                Text("अंतराल", comment: "Interval")
                    .paddedSubheadlineTextFormat()
                Spacer()
            }
            
            VStack {
                Text(model.localizedDateInterval)
                    .paddedTitle2TextFormat()
                HStack {
                    Text("तारीख़", comment: "Date")
                        .subheadlineTextFormat()
                    
                    Spacer()
                    Picker("", selection: $model.dateStyle) {
                        Text(verbatim: "∅").tag(DateIntervalFormatter.Style.none)
                        Text(verbatim: "•").tag(DateIntervalFormatter.Style.short)
                        Text(verbatim: "••").tag(DateIntervalFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateIntervalFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateIntervalFormatter.Style.full)
                    }
                    .pickerStyle(.segmented)
                }
                HStack {
                    Text("समय", comment: "Time")
                        .subheadlineTextFormat()
                    
                    Spacer()
                    Picker("", selection: $model.timeStyle) {
                        Text(verbatim: "∅").tag(DateIntervalFormatter.Style.none)
                        Text(verbatim: "•").tag(DateIntervalFormatter.Style.short)
                        Text(verbatim: "••").tag(DateIntervalFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateIntervalFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateIntervalFormatter.Style.full)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 5)
                }
                
            }
            .opaqueBackground()
        }
    }
}
