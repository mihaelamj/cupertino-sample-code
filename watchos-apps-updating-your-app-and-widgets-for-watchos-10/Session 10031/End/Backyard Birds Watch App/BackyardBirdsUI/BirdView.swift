/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of a bird.
*/

import SwiftUI

struct BirdView: View {
    var bird: Bird
    
    var body: some View {
        Image.bird
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .colorMultiply(Color(hue: bird.hueRotation, saturation: 0.5, brightness: 0.9))
    }
}

struct BirdView_Previews: PreviewProvider {
    static var previews: some View {
        BirdView(bird: .preview)
    }
}
