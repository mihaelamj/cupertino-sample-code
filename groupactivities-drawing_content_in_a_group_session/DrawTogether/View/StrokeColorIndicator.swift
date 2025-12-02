/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The color to apply when drawing new strokes.
*/

import SwiftUI

struct StrokeColorIndicator: View {
    let color: Color

    var body: some View {
        Circle()
            .foregroundColor(color)
            .frame(width: 25, height: 25)
            .overlay(
                Circle()
                    .stroke()
                    .padding(2)
                    .foregroundColor(Color(uiColor: .systemBackground))
            )
    }
}

struct StrokeColorIndicator_Previews: PreviewProvider {
    static var previews: some View {
        StrokeColorIndicator(color: .yellow)
            .previewLayout(.sizeThatFits)
    }
}
