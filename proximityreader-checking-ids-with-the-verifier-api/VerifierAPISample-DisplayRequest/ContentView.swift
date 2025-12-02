/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view that provides the document reader user interface.
*/

import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        Button("Verify ID Document") {
            viewModel.verifyButtonTapped()
        }
        .buttonStyle(.borderedProminent)
    }

}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        ContentView()
    }

}
