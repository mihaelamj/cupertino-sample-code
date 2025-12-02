/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header image view.
*/

import SwiftUI

struct HeaderImage: View {
    let name: String
    
    var body: some View {
        Image(systemName: name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 75)
            .foregroundStyle(Color.accentColor)
    }
}

#Preview {
    HeaderImage(name: "clock")
    HeaderImage(name: "globe")
    HeaderImage(name: "person")
    HeaderImage(name: "speedometer")
}
