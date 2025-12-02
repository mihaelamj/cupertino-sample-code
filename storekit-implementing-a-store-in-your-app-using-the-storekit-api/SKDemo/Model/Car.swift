/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A car.
*/

import StoreKit
import SwiftUI

enum Car: String, CaseIterable, Identifiable {
    case sedan
    case suv
    case pickupTruck

    init?(_ productID: Product.ID) {
        switch productID {
        case Car.sedan.id:
            self = .sedan
        case Car.suv.id:
            self = .suv
        case Car.pickupTruck.id:
            self = .pickupTruck
        case _:
            return nil
        }
    }

    var decorativeIconName: String {
        switch self {
        case .sedan:
            ImageNameConstants.Car.sedan
        case .suv:
            ImageNameConstants.Car.suv
        case .pickupTruck:
            ImageNameConstants.Car.pickupTruck
        }
    }

    var displayName: String {
        switch self {
        case .sedan:
            "Sedan"
        case .suv:
            "SUV"
        case .pickupTruck:
            "Pickup Truck"
        }
    }

    var description: String {
        switch self {
        case .sedan:
            "A standard four-seater"
        case .suv:
            "Off-road vehicle"
        case .pickupTruck:
            "Medium duty truck"
        }
    }

    var id: Product.ID? {
        Store.productID(for: self)
    }

    var metrics: Set<Car.Metric> {
        switch self {
        case .sedan:
            [
                .speed(75),
                .fuel(50),
                .traction(60)
            ]
        case .suv:
            [
                .speed(60),
                .fuel(60),
                .traction(75)
            ]
        case .pickupTruck:
            [
                .speed(50),
                .fuel(40),
                .traction(100)
            ]
        }
    }
}

extension EnvironmentValues {
    @Entry var selectedCar: Car = CustomerEntitlements.freeCar
}
