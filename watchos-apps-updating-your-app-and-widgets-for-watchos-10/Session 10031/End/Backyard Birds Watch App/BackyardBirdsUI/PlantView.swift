/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of a plant.
*/

import SwiftUI

struct PlantView: View {
    var plant: Plant
    var index: Int

    var body: some View {
        Image.plant
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .colorMultiply(.init(white: 1.0 - (0.1 * Double(index))))
    }
}

struct PlantView_Previews: PreviewProvider {
    static var previews: some View {
        PlantView(plant: .preview, index: 0)
    }
}
