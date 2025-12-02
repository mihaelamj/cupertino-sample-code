/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom button style used throughout the app.
*/

import SwiftUI

struct SelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let inactiveColor = Color.gray.opacity(0.2)
        let activeColor = Color.green
        
        return configuration.label
            .padding()
            .background(configuration.isPressed ? activeColor : inactiveColor)
            .cornerRadius(15)
            .hoverEffect(.highlight)
            .contentShape(Rectangle())
    }
}

