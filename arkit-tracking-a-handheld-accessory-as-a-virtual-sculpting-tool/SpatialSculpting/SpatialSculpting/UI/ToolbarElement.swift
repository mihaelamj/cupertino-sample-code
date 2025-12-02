/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Toolbar UI element.
*/

import SwiftUI

struct ToolbarElement: View {
    let name: String
    var body: some View {
        Text(name)
            .font(.subheadline)
            .padding()
            .glassBackgroundEffect(in: .capsule)
    }
    
}
