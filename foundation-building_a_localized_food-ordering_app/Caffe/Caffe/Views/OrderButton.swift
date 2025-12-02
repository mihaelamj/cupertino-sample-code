/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A stylized button that performs an ordering action.
*/

import SwiftUI

struct OrderButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

struct OrderButton_Previews: PreviewProvider {
    static var previews: some View {
        Button("Button") {}
            .buttonStyle(OrderButtonStyle())
    }
}
