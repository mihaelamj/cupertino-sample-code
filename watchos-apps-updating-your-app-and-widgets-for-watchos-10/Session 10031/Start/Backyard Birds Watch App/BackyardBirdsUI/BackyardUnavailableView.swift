/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A fallback view when a backyard is unavailable.
*/

import SwiftUI

struct BackyardUnavailableView: View {
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.octagon")
                .imageScale(.large)
                .symbolRenderingMode(.multicolor)
            Text("We couldn't find that backyard!")
                .multilineTextAlignment(.center)
        }
    }
}

struct BackyardUnavailableView_Previews: PreviewProvider {
    static var previews: some View {
        BackyardUnavailableView()
    }
}
