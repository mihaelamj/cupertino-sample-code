/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model to update the items in the carousel.
*/

import SwiftUI

@Observable
final class CarouselModel {
    /// All of the items in the carousel.
    var items: [CarouselItem] {
        didSet {
            updateNormalizedZPositions()
        }
    }

    @ObservationIgnored
    /// The front-most item is the selected item.
    var selectedItem: CarouselItem {
        return items.min(by: { $0.zPosition < $1.zPosition })!
    }

    /// Store all of the z positions.
    var normalizedZPosition: [Double] = []

    let degreeToSnapTo: Int
    let cutoffAngle: Int

    init() {
        let items: [CarouselItem] = [
            .init(name: "Mt. Fuji", country: "Japan", entityName: "CarouselFuji"),
            .init(name: "Gaurishankar", country: "Nepal", entityName: "CarouselGaurishankar"),
            .init(name: "Grand Canyon", country: "USA", entityName: "CarouselGrandCanyon"),
            .init(name: "Kirkjufell", country: "Iceland", entityName: "CarouselKirkjufell"),
            .init(name: "Mt. Everest", country: "Nepal", entityName: "CarouselEverest")
        ]
        
        degreeToSnapTo = Int(360.0 / Double(items.count))
        cutoffAngle = degreeToSnapTo / 2
        self.items = items
        updateNormalizedZPositions()
    }

    /// Update the z position of each item in the carousel between `0.3` and `1.3`.
    func updateNormalizedZPositions() {
        // The item closest to the front of the volume.
        guard
            let min = items.min(by: { $0.zPosition < $1.zPosition }),
            let max = items.max(by: { $0.zPosition < $1.zPosition })
        else {
            normalizedZPosition = []
            return
        }

        // Don't allow the minimum value to be `0` so that all items are visible when used to set opacity.
        let minimumValue: Double = 0.3
        // Normalize along `0.3` to `1.3`.
        normalizedZPosition = items.map { (($0.zPosition - min.zPosition) / (max.zPosition - min.zPosition)) - minimumValue }
    }
}
