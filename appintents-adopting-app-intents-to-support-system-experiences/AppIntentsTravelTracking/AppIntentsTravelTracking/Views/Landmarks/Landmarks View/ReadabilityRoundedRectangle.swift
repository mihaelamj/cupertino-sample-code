/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct ReadabilityRoundedRectangle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Constants.cornerRadius)
            .foregroundStyle(.clear)
            .background(
                LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center)
            )
            .containerRelativeFrame(.vertical)
            .clipped()
    }
}

