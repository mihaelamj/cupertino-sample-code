/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The date formatter view.
*/

import SwiftUI

struct DateFormatterView: View {
    @Bindable var model: DateFormatterModel
    
    var body: some View {
        VStack {
            // Styles
            VStack {
                Text(model.localizedDate)
                    .paddedTitle2TextFormat()
                HStack {
                    Text("तारीख़", comment: "Date")
                        .subheadlineTextFormat()
                    
                    Spacer()
                    Picker("", selection: $model.dateStyle) {
                        Text(verbatim: "∅").tag(DateFormatter.Style.none)
                        Text(verbatim: "•").tag(DateFormatter.Style.short)
                        Text(verbatim: "••").tag(DateFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateFormatter.Style.full)
                    }
                    .pickerStyle(.segmented)
                }
                HStack {
                    Text("समय", comment: "Time")
                        .subheadlineTextFormat()
                    
                    Spacer()
                    Picker("", selection: $model.timeStyle) {
                        Text(verbatim: "∅").tag(DateFormatter.Style.none)
                        Text(verbatim: "•").tag(DateFormatter.Style.short)
                        Text(verbatim: "••").tag(DateFormatter.Style.medium)
                        Text(verbatim: "•••").tag(DateFormatter.Style.long)
                        Text(verbatim: "••••").tag(DateFormatter.Style.full)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 5)
                }
            }
            .opaqueBackground()
            
            // Templates
            VStack {
                Text(model.localizedDateWithPattern)
                    .paddedTitle2TextFormat()
                
                HStack {
                    Text("टेंप्लेट", comment: "Template")
                        .subheadlineTextFormat()
                    
                    Text(model.template)
                        .font(.system(size: 14, design: .monospaced))
                    
                    // Allows easy copying of the template.
                    Button {
                        writeToPasteboard(model.template)
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                HStack {
                    Text("तारीख़ प्रारूप", comment: "Date Format")
                        .subheadlineTextFormat()
                    
                    Text(model.dateFormat)
                        .font(.system(size: 14, design: .monospaced))
                    Spacer()
                }
                .padding(.top, 10)
                
                ForEach(model.templateFields) { templateField in
                    HStack {
                        Text(templateField.title)
                            .subheadlineTextFormat()
                        Spacer()
                        Picker("", selection: $model.selectedPatterns[templateField.id]) {
                            ForEach(templateField.patterns.indices, id: \.self) { index in
                                if templateField.patterns[index] == "" {
                                    Text(verbatim: "∅").tag(templateField.patterns[index])
                                } else {
                                    Text(model.lengthIndicator(length: index)).tag(templateField.patterns[index])
                                }
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .opaqueBackground()
        }
    }
}
