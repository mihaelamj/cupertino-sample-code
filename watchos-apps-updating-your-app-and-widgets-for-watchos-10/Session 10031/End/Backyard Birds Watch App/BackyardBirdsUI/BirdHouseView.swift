/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of a birdhouse.
*/

import SwiftUI

struct BirdHouseView: View {
    var birdHouse: BirdHouse

    var body: some View {
        Image.birdBath
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

struct BirdHouseView_Previews: PreviewProvider {
    static var previews: some View {
        BirdHouseView(birdHouse: .preview)
    }
}
