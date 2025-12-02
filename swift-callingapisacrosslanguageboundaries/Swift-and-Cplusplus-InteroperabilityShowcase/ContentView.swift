/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view that embeds the forest view.
*/

import SwiftUI
import ForestUI

struct ContentView: View {
    var body: some View {
        ForestView(forest: createEnchantedForest())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
