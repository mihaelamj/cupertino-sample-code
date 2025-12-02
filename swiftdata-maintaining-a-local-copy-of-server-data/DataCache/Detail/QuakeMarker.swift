/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A map annotation that represents a single earthquake.
*/

import SwiftUI
import MapKit

/// A map annotation that represents a single earthquake.
struct QuakeMarker: MapContent {
    var quake: Quake
    var selected: Bool

    var body: some MapContent {
        Annotation(coordinate: quake.location.coordinate) {
            QuakeCircle(quake: quake, selected: selected)
        } label: {
            Text(quake.location.name)
        }
        .tag(quake)
        .annotationTitles(.hidden)
    }
}

/// The colorful circle that represents a single earthquake.
private struct QuakeCircle: View {
    var quake: Quake
    var selected: Bool

    var body: some View {
        Circle()
            .stroke(
                selected ? Color.black : .gray,
                style: .init(lineWidth: selected ? 2 : 1))
            .fill(quake.color.opacity(selected ? 1 : 0.5))
            .frame(width: quake.markerSize.width, height: quake.markerSize.width)
    }
}

#Preview {
    ModelContainerPreview(PreviewSampleData.inMemoryContainer) {
        VStack {
            QuakeCircle(quake: .xxsmall, selected: false)
            QuakeCircle(quake: .xsmall, selected: false)
            QuakeCircle(quake: .medium, selected: false)
            QuakeCircle(quake: .large, selected: true)
            QuakeCircle(quake: .xlarge, selected: false)
            QuakeCircle(quake: .xxlarge, selected: false)
            QuakeCircle(quake: .xxxlarge, selected: false)
        }
    }
}
