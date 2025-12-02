/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows how contenders rank relative to one another.
*/

import SwiftUI

/// A view that shows how contenders rank relative to one another.
///
/// This view makes use of the custom radial layout ``MyRadialLayout`` to show
/// pet avatars in a circle, arranged according to their ranks. The radial
/// layout can calculate an offset that creates an appropriate arrangement for
/// all but one set of rankings: there's no way to show a three-way tie with the
/// avatars in a circle. To resolve this, the view detects this condition and
/// and uses it to put the avatars in a line instead using the
/// [`HStackLayout`](https://developer.apple.com/documentation/swiftui/hstacklayout)
/// type, which is a version of the built-in
/// [`HStack`](https://developer.apple.com/documentation/swiftui/hstack)
/// that conforms to the
/// [`Layout`](https://developer.apple.com/documentation/swiftui/layout)
/// protocol. To transition between the layout types, the app uses the
/// [`AnyLayout`](https://developer.apple.com/documentation/swiftui/anylayout)
/// type.
///
/// ```swift
/// let layout = model.isAllWayTie ? AnyLayout(HStackLayout()) : AnyLayout(MyRadialLayout())
///
/// Podium()
///     .overlay(alignment: .top) {
///         layout {
///             ForEach(model.pets) { pet in
///                 Avatar(pet: pet)
///                     .rank(model.rank(pet))
///             }
///         }
///         .animation(.default, value: model.pets)
///     }
/// ```
///
/// Because the structural identity of the views remains the same throughout, the
/// [`animation(_:value:)`](https://developer.apple.com/documentation/swiftui/view/animation(_:value:))
/// view modifier creates animated transitions between layout types. The
/// modifier also animates radial layout changes that result from changes in
/// the rankings because the calculated offsets depend on the same pet data.
///
/// > Important: This view assumes that the model contains exactly three pets.
/// Any other number results in undefined behavior.
///
/// - Tag: Profile
struct Profile: View {
    @EnvironmentObject private var model: Model

    var body: some View {
        // Use a horizontal layout for a tie; use a radial layout, otherwise.
        let layout = model.isAllWayTie ? AnyLayout(HStackLayout()) : AnyLayout(MyRadialLayout())

        Podium()
            .overlay(alignment: .top) {
                layout {
                    ForEach(model.pets) { pet in
                        Avatar(pet: pet)
                            .rank(model.rank(pet))
                    }
                }
                .animation(.default, value: model.pets)
            }
    }
}

/// A SwiftUI preview provider for the view that shows the ranked, pet avatars.
struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
            .environmentObject(Model.previewData)
    }
}
