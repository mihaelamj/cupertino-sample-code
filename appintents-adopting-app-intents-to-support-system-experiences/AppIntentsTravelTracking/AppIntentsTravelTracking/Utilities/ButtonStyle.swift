/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object with custom button styles.
*/

import SwiftUI

// Custom button style for a scale effect when tapping a button.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
}
