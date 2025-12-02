/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows buttons that people tap to vote for their favorite pet.
*/

import SwiftUI

/// A view that shows buttons that people tap to vote for their favorite pet,
/// arranged in a way that best fits available space.
///
/// The size of the voting buttons that this view displays depends on the width
/// of the text they contain. For people that speak another language or that
/// use a larger text size, the horizontal arrangement provided by the default
/// ``MyEqualWidthHStack`` layout might not fit in the display. So this view uses
/// [`ViewThatFits`](https://developer.apple.com/documentation/swiftui/viewthatfits)
/// to let SwiftUI choose between that and an alternative vertical arrangement
/// provided by the ``MyEqualWidthVStack`` layout:
///
/// ```swift
/// ViewThatFits { // Choose the first view that fits.
///     MyEqualWidthHStack { // Arrange horizontally if it fits...
///         Buttons()
///     }
///     MyEqualWidthVStack { // ...or vertically, otherwise.
///         Buttons()
///     }
/// }
/// ```
///
/// - Tag: ButtonStack
struct ButtonStack: View {
    var body: some View {
        ViewThatFits { // Choose the first view that fits.
            MyEqualWidthHStack { // Arrange horizontally if it fits...
                Buttons()
            }
            MyEqualWidthVStack { // ...or vertically, otherwise.
                Buttons()
            }
        }
    }
}

/// A set of buttons that enable voting for the different pets.
///
/// This is just a list of buttons, and depends on its container view to do
/// the layout.
private struct Buttons: View {
    @EnvironmentObject private var model: Model

    var body: some View {
        ForEach($model.pets) { $pet in
            Button {
                pet.votes += 1
            } label: {
                Text(pet.type)
                    .frame(maxWidth: .infinity) // Expand to fill the offered space.
            }
            .buttonStyle(.bordered)
        }
    }
}

/// A SwiftUI preview provider for the voting buttons.
struct ButtonStack_Previews: PreviewProvider {
    static var previews: some View {
        ButtonStack()
            .environmentObject(Model.previewData)
    }
}
