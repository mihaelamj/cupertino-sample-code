/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view modifier that draws a shadow.
*/

import SwiftUI

/// A view modifier that creates the shadow effect used on views throughout the app.
struct ShadowBuilder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 0)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 10, y: 10)
            .shadow(color: Color.white.opacity(0.6), radius: 10, x: -5, y: -5)
    }
}

extension View {
    func standardShadow() -> some View {
        return modifier(ShadowBuilder())
    }
}
