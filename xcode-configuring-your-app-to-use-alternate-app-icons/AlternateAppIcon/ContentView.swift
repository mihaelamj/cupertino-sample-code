/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's top level view.
*/

import SwiftUI

struct ContentView: View {
    @State private var model = Model()
     
    var body: some View {
        IconChooser()
            .environment(model)
    }
}

#Preview {
    ContentView()
        .environment(Model())
}
