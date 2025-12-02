/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions and supporting SwiftUI types.
*/

import SwiftUI

let primaryButtonSize = CGSize(width: 68, height: 68)
let secondaryButtonSize = CGSize(width: 64, height: 64)

extension View {
    func debugBorder(color: Color = .red) -> some View {
        self
            .border(color)
    }
}

extension Image {
    init(_ image: CGImage) {
        self.init(uiImage: UIImage(cgImage: image))
    }
}
