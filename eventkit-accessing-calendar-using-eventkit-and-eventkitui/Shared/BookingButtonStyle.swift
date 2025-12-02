/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Styles a booking button.
*/

import SwiftUI

struct BookingButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .bottom)
            .foregroundStyle(.background)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isEnabled ? Color.blue : .gray.opacity(0.6))
                    .opacity(configuration.isPressed ? 0.8 : 1)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1)
                    .animation(.easeInOut, value: configuration.isPressed)
            }
    }
}

extension ButtonStyle where Self == BookingButtonStyle {
    static var booking: BookingButtonStyle {
        BookingButtonStyle()
    }
}
