/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows the rest stop popover.
*/

import SwiftUI
import RealityKit
import Observation

struct RestStopDetailView: View {
    let featuredImageName: String
    let restStop: RestStop

    @State private var showDatePicker: Bool = false

    var body: some View {
        PopoverView(
            title: restStop.name,
            imageName: featuredImageName,
            description: restStop.description
        ) {
            if !restStop.locations.isEmpty {
                HStack(spacing: 20) {
                    ForEach(restStop.locations, id: \.trailPercentage) { location in
                        RestStopLocationButton(location: location)
                    }
                }
            }
        }
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    let restStopWithOneLocation = RestStop(
        name: "3 Mile Resthouse",
        entityName: "Rest_Hut",
        locations: [RestStopLocation(restStopDirection: .descent, trailPercentage: 0.2864)],
        description: MockData.threeMileResthouseDescription
    )

    let restStopWithTwoLocations = RestStop(
        name: "3 Mile Resthouse",
        entityName: "Rest_Hut",
        locations: [
            RestStopLocation(restStopDirection: .descent, trailPercentage: 0.2864),
            RestStopLocation(restStopDirection: .ascent, trailPercentage: 0.7136)
        ],
        description: MockData.threeMileResthouseDescription
    )

    HStack(spacing: 30) {
        RestStopDetailView(
            featuredImageName: "BrightAngelHeroShot",
            restStop: restStopWithOneLocation
        )
        .environment(\.dynamicTypeSize, .xSmall)

        RestStopDetailView(
            featuredImageName: "BrightAngelHeroShot",
            restStop: restStopWithTwoLocations
        )
        .environment(\.dynamicTypeSize, .large)

        RestStopDetailView(
            featuredImageName: "BrightAngelHeroShot",
            restStop: restStopWithTwoLocations
        )
        .environment(\.dynamicTypeSize, .xxxLarge)
    }
}
