/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of custom view modifiers.
*/

import SwiftUI

private enum Constants {
    static let backgroundColor1 = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let backgroundColor2 = Color(red: 0.9, green: 0.9, blue: 0.9)
}

extension View {
    func attachment() -> some View {
        modifier(AttachmentViewModifier())
    }
}

private struct AttachmentViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(25)
            .background(LinearGradient(
                gradient: Gradient(colors: [Constants.backgroundColor1, Constants.backgroundColor2]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .font(.system(.body, design: .rounded))
            .foregroundStyle(.black)
    }
}

struct AttachmentButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding()
            .font(.system(.title, design: .rounded))
            .frame(maxWidth: .infinity)
            .foregroundStyle(.black.opacity(0.7))
            .background(.gray.opacity(0.7))
            .clipShape(Capsule())
            .contentShape(Capsule())
            .hoverEffect(.highlight)
    }
}
