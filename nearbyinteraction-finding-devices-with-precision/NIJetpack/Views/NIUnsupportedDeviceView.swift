/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays when the person's device doesn't support the necessary features.
*/

import SwiftUI

struct NIUnsupportedDeviceView: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark.circle")
                    .resizable()
                .frame(width: 50, height: 50, alignment: .center)
            Text("Unsupported Device")
        }
        .padding()
        .foregroundColor(.red)
    }
}

struct NIUnsupportedView_Previews: PreviewProvider {
    static var previews: some View {
        NIUnsupportedDeviceView()
    }
}
