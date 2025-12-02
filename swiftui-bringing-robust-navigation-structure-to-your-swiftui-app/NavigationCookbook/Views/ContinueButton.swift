/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A confirmation button, custom styled for iOS.
*/

import SwiftUI

struct ContinueButton: View {
    var action: () -> Void
    var body: some View {
        Button("Continue", action: action)
            #if os(macOS)
            .buttonStyle(.borderedProminent)
            #else
            .buttonStyle(ContinueButtonStyle())
            #endif
    }
}

#if os(iOS)
struct ContinueButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .frame(maxWidth: horizontalSizeClass == .compact ?
                .infinity : 280)
            .foregroundStyle(.background)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isEnabled ? Color.accentColor : .gray.opacity(0.6))
                    .opacity(configuration.isPressed ? 0.8 : 1)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1)
                    .animation(.easeInOut, value: configuration.isPressed)
            }
    }
}
#endif

#Preview() {
    ContinueButton { }
}
