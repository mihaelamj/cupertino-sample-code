/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Populates the navigation bar with the "Recipe of the Day" and experience buttons.
*/

import SwiftUI

struct ExperienceToolbarViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ExperienceButton()
            }
    }
}

extension View {
    func experienceToolbar() -> some View {
        modifier(ExperienceToolbarViewModifier())
    }
}

#Preview() {
    NavigationStack {
        Color.white
            .experienceToolbar()
    }
}
