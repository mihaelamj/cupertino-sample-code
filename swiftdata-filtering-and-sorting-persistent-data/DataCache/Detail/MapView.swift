/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A detail view that displays a map with an annotation for each stored quake.
*/

import SwiftUI
import SwiftData
import MapKit
import simd

/// A detail view that displays a map with an annotation for each stored quake.
struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quake.magnitude, order: .reverse) private var quakes: [Quake]

    @Binding var selectedId: Quake.ID?
    @Binding var selectedIdMap: Quake.ID?

    init(
        selectedId: Binding<Quake.ID?>,
        selectedIdMap: Binding<Quake.ID?>,
        searchDate: Date = .now,
        searchText: String = ""
    ) {
        _selectedId = selectedId
        _selectedIdMap = selectedIdMap

        _quakes = Query(
            filter: Quake.predicate(
                searchText: searchText,
                searchDate: searchDate),
            sort: \.magnitude,
            order: .reverse
        )
    }

    var body: some View {
        Map(selection: $selectedIdMap) {
            ForEach(quakes) { quake in
                QuakeMarker(quake: quake, selected: quake.id == selectedId)
            }
        }
        .mapStyle(.standard(
            elevation: .flat,
            emphasis: .muted,
            pointsOfInterest: .excludingAll))
        .mapCameraKeyframeAnimator(trigger: selectedId) { initialCamera in
            let start = initialCamera.centerCoordinate
            let end = quakes[selectedId]?.location.coordinate ?? start
            let travelDistance = start.distance(to: end)

            let duration = max(min(travelDistance / 30, 5), 1)
            let finalAltitude = travelDistance > 20 ? 3_000_000 : min(initialCamera.distance, 3_000_000)
            let middleAltitude = finalAltitude * max(min(travelDistance / 5, 1.5), 1)

            KeyframeTrack(\MapCamera.centerCoordinate) {
                CubicKeyframe(end, duration: duration)
            }
            KeyframeTrack(\MapCamera.distance) {
                CubicKeyframe(middleAltitude, duration: duration / 2)
                CubicKeyframe(finalAltitude, duration: duration / 2)
            }
        }

        // Synchronize changes from the main selector into the map.
        .onChange(of: selectedId) { _, selectedId in
            guard selectedId != selectedIdMap else { return }
            selectedIdMap = selectedId
        }
    }
}

extension CLLocationCoordinate2D {
    /// Calculates a value that's proportional to the distance between two points.
    fileprivate func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        simd.distance(
            SIMD2<Double>(x: latitude, y: longitude),
            SIMD2<Double>(x: coordinate.latitude, y: coordinate.longitude))
    }
}

#Preview {
    MapView(selectedId: .constant(nil), selectedIdMap: .constant(nil))
}
