/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The formatter view for date components.
*/
import SwiftUI

struct DateComponentsFormatterView: View {
    @Bindable var model: DateComponentsModel
    
    var body: some View {
        VStack {
            HStack {
                Text("अवधि", comment: "Duration")
                    .paddedSubheadlineTextFormat()
                Spacer()
            }
            
            VStack {
                Text(model.localizedDuration)
                    .paddedTitle2TextFormat()
                HStack {
                    Picker("", selection: $model.dateComponentsStyle) {
                        Text(verbatim: "•").tag(DateComponentsFormatter.UnitsStyle.positional)
                        Text(verbatim: "••").tag(DateComponentsFormatter.UnitsStyle.abbreviated)
                        Text(verbatim: "•••").tag(DateComponentsFormatter.UnitsStyle.brief)
                        Text(verbatim: "••••").tag(DateComponentsFormatter.UnitsStyle.short)
                        Text(verbatim: "•••••").tag(DateComponentsFormatter.UnitsStyle.full)
                        Text(verbatim: "••••••").tag(DateComponentsFormatter.UnitsStyle.spellOut)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .opaqueBackground()
        }
    }
}
