/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that hosts the image of the backyard.
*/

import SwiftUI

struct BackyardImage: View {
    var backyard: Backyard

    var body: some View {
        Rectangle().fill(.clear).overlay {
            Image(backyard.imageName)
                .resizable()
                .scaledToFill()
        }
        .clipShape(.containerRelative)
    }
}
