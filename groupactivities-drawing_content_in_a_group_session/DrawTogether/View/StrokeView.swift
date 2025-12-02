/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to draw an individual stroke.
*/

import SwiftUI

struct StrokeView: View {
    @ObservedObject var stroke: Stroke

    var body: some View {
        stroke.path
            .stroke(stroke.color.uiColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
}

struct StrokeView_Previews: PreviewProvider {
    static var previews: some View {
        StrokeView(stroke: Stroke(color: .red))
            .previewLayout(.sizeThatFits)
    }
}
