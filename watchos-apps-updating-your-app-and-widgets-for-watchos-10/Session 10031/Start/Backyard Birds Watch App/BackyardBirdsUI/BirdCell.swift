/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of a bird.
*/

import SwiftUI

struct BirdCell: View {
    let bird: Backyard.BackyardBird
    
    var body: some View {
        HStack(spacing: 8) {
            Image(bird.imageName)
            Text(bird.name)
        }
    }
}
