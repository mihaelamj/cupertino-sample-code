/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for names.
*/

import SwiftUI

struct NamesView: View {
    @State private var model = NamesModel()
    
    var body: some View {
        ScrollView {
            VStack {
                /*
                    If `abbreviatedName` is more than two characters long, the app display a person icon.
                    Otherwise, the app displays a generic symbol.
                */
                if model.abbreviatedName.count > 2 {
                    HeaderImage(name: "person")
                } else {
                    MonogramView(nameComponents: model.selectedNameComponents, color: .accentColor, sideLength: 75)
                }
            }
        
            VStack {
                Text(model.name)
                    .font(.title2)
                    .padding(.top, 10)
                    .multilineTextAlignment(.center)
                
                if !model.phoneticName.isEmpty {
                    Text(model.phoneticName)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.top, 10)
                        .multilineTextAlignment(.center)
                }
                
                Picker("", selection: $model.selectedIndex) {
                    ForEach(model.names.indices, id: \.self) { index in
                        Text(PersonNameComponentsFormatter.localizedString(from: model.names[index], style: .medium, options: [])).tag(index)
                    }
                }
                
                Picker("", selection: $model.selectedStyle) {
                    Text(verbatim: "••").tag(PersonNameComponentsFormatter.Style.short)
                    Text(verbatim: "•••").tag(PersonNameComponentsFormatter.Style.medium)
                    Text(verbatim: "••••").tag(PersonNameComponentsFormatter.Style.long)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .opaqueBackground()
        }
    }
}
