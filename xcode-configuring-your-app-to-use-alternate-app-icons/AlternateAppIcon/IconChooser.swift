/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view displaying the selected icon and a collection of alternate icons from which you can make a selection.
*/

import SwiftUI

struct IconChooser: View {
    @Environment(Model.self) var model: Model
    private let columns = Array(repeating: GridItem(.adaptive(minimum: 114, maximum: 1024), spacing: 10), count: 3)
   
    var body: some View {
        VStack {
            HStack {
                Text("Select an icon color:")
                    .font(.largeTitle)
                    Circle()
                        .foregroundStyle(model.appIcon.color)
                        .frame(maxHeight: 114)
            }
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(Icon.allCases) { icon in
                        Button {
                            model.setAlternateAppIcon(icon: icon)
                        } label: {
                            Circle()
                              .foregroundStyle(icon.color)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    IconChooser()
        .environment(Model())
}
