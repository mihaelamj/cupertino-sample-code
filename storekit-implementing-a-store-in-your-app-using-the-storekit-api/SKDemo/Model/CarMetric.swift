/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model describing the metrics of a Car.
*/

import Foundation

extension Car {
    struct Metric: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let value: UInt8
    }
}

extension Car.Metric {
    static func speed(_ value: UInt8) -> Car.Metric {
        .init(name: "Speed", value: value)
    }
    static func fuel(_ value: UInt8) -> Car.Metric {
        .init(name: "Fuel", value: value)
    }
    static func traction(_ value: UInt8) -> Car.Metric {
        .init(name: "Traction", value: value)
    }
}
