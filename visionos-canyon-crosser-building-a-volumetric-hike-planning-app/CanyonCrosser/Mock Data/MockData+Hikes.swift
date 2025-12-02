/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Hikes in the Grand Canyon.
*/

import Foundation

extension MockData {

    // MARK: Hikes
    static let trailOfTime = Hike(
        name: "Trail of Time Hike",
        description: trailOfTimeDescription,
        trailEntityPath: "",
        featuredImageName: "BrightAngelHeroShot",
        trailStartEntityName: "TrailOfTimeTrailhead",
        trailEndEntityName: "Trail_End",
        length: 9,
        trailhead: Trailhead(
            name: "Trailhead",
            entityName: "TrailOfTimeTrailhead"
        )
    )

    static let matherPoint = Hike(
        name: "Mather Point Hike",
        description: matherPointDescription,
        trailEntityPath: "",
        featuredImageName: "BrightAngelHeroShot",
        trailStartEntityName: "MatherPointTrailhead",
        trailEndEntityName: "Trail_End",
        length: 2.5,
        trailhead: Trailhead(
            name: "Trailhead",
            entityName: "MatherPointTrailhead"
        )
    )

    static let brightAngel = Hike(
        name: "Bright Angel Trail Hike",
        description: brightAngelDescription,
        trailEntityPath: "Terrain/Trail/Trail_Line",
        featuredImageName: "BrightAngelHeroShot",
        trailStartEntityName: "BrightAngelTrailhead",
        trailEndEntityName: "Trail_End",
        length: 9,
        trailhead: Trailhead(
            name: "Trailhead",
            entityName: "BrightAngelTrailhead"
        ),
        restStops: [
            RestStop(
                name: "3 Mile Resthouse",
                entityName: "Rest_Hut",
                locations: [
                    RestStopLocation(restStopDirection: .descent, trailPercentage: 0.1183),
                    RestStopLocation(restStopDirection: .ascent, trailPercentage: 0.8835)
                ],
                description: threeMileResthouseDescription
            ),
            RestStop(
                name: "Havasupai Gardens",
                entityName: "Garden",
                locations: [
                    RestStopLocation(restStopDirection: .descent, trailPercentage: 0.3521),
                    RestStopLocation(restStopDirection: .ascent, trailPercentage: 0.6491)
                ],
                description: havasupaiGardensDescription
            ),
            RestStop(
                name: "Colorado River",
                entityName: "Trail_End",
                locations: [
                    RestStopLocation(restStopDirection: .base, trailPercentage: 0.5)
                ],
                description: endOfTrailDescription
            )
        ]
    )
}
