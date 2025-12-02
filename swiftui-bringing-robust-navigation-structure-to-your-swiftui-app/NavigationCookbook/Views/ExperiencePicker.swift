/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A navigation experience picker used to select the navigation architecture
 for the app.
*/

import SwiftUI

struct ExperiencePicker: View {
    @Binding var experience: Experience?
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Experience?
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Choose your navigation experience")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .padding()
                Spacer()
                LazyVGrid(columns: columns) {
                    ForEach(Experience.allCases) { experience in
                        ExperiencePickerItem(
                            selection: $selection,
                            experience: experience)
                    }
                }
                Spacer()
            }
            .scenePadding()
            #if os(iOS)
            .safeAreaInset(edge: .bottom) {
                ContinueButton(action: continueAction)
                    .disabled(selection == nil)
                    .scenePadding()
            }
            #endif
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                ContinueButton(action: continueAction)
                    .disabled(selection == nil)
            }
        }
        .frame(width: 600, height: 350)
        #endif
        .interactiveDismissDisabled(selection == nil)
    }
    
    var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: 250)) ]
    }
    
    func continueAction() {
        experience = selection
        dismiss()
    }
}

#Preview() {
    ExperiencePicker(experience: .constant(.stack))
}
