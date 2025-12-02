/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension of `Image` that creates a value from data.
*/

import SwiftUI

extension Image {
    init(data: Data) {
        let platformImage = UIImage(data: data)!
        self.init(uiImage: platformImage)
    }
}
