/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model describing the In-App Purchases merchandised within the app.
*/

import SwiftUI

extension Car {
    enum Item: String, CaseIterable, Identifiable {
        case boosts
        case fuel

        var id: String { rawValue }

        var title: String {
            rawValue.capitalized
        }

        var caption: String? {
            switch self {
            case .boosts:
                "Temporarily increase your speed"
            case .fuel:
                "Refuel"
            }
        }

        var decorativeIconName: String {
            switch self {
            case .boosts:
                ImageNameConstants.CarItem.boosts
            case .fuel:
                ImageNameConstants.CarItem.fuel
            }
        }

        @ViewBuilder
        func storeView(isPurchasing: Binding<Bool>) -> some View {
            switch self {
            case .boosts:
                BoostStore(isPurchasing: isPurchasing)
            case .fuel:
                FuelStore(isPurchasing: isPurchasing)
            }
        }
    }
}
