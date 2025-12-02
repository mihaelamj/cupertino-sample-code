/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Create an image from the given sloth.
*/

import SwiftUI

/// An extension that facilitates the display of sloths in user interfaces.
public extension Image {
    /// Create an image from the given sloth.
    ///
    /// ```swift
    /// let iceSloth = Sloth(name: "Super Sloth", color: .blue, power: .ice)
    ///
    /// var body: some View {
    ///     Image(iceSloth)
    ///         .resizable()
    ///         .aspectRatio(contentMode: .fit)
    ///     Text(iceSloth.name)
    /// }
    /// ```
    ///
    /// ![A screenshot of an ice sloth, with the text Super Sloth underneath.](iceSloth)
    ///
    /// This initializer is useful for displaying static sloth
    /// images. To create an interactive view containing a sloth,
    /// use ``SlothView``.
    init(_ sloth: Sloth) {
        self.init("\(sloth.power)-sloth")
    }
}
