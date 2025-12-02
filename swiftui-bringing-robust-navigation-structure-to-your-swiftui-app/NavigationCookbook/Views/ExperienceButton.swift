/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An button that presents the navigation experience picker when its action
 is invoked.
*/

import SwiftUI

struct ExperienceButton: View {
    @Environment(NavigationModel.self) private var navigationModel
    
    var body: some View {
        Button {
            navigationModel.showExperiencePicker = true
        } label: {
            Label("Experience", systemImage: "wand.and.stars")
                .help("Choose your navigation experience")
        }
    }
}

#Preview() {
    ExperienceButton()
        .environment(NavigationModel.shared)
}
