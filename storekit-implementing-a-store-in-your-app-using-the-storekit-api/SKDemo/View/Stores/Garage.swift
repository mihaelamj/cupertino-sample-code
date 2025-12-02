/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A place for the user to select which car they want to use.
*/

import StoreKit
import SwiftUI

struct Garage: View {
    @Binding var selectedCar: Car
    @Binding var isPurchasing: Bool

    var body: some View {
        VStack {
            VStack(spacing: SharedLayoutConstants.defaultVerticalSpacing) {
                Text(verbatim: "Garage")
                    .font(.title3.weight(.medium))
                    .padding(.top)
                CustomDivider()
                    .padding(.vertical)
            }
            ForEach(Car.allCases) { car in
                if let id = car.id {
                    ProductView(id: id)
                        .productViewStyle(.car(selectedCar: $selectedCar, isPurchasing: isPurchasing))
                } else {
                    GarageRow(car: car) {
                        Button {
                            withAnimation {
                                selectedCar = car
                            }
                        } label: {

                        }
                        .buttonStyle(
                            .garageRowButton(
                                hasCurrentEntitlement: true,
                                car: car
                            )
                        )
                    }
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(.horizontal)
        .onInAppPurchaseStart { _ in
            isPurchasing = true
        }
        .onInAppPurchaseCompletion { _, result in
            Task {
                defer { isPurchasing = false }
                if let purchaseResult = try? result.get() {
                    await Store.shared.process(purchaseResult: purchaseResult)
                }
            }
        }
    }
}

private struct GarageRow<Button: View>: View {
    private let car: Car
    private let button: Button

    init(car: Car, @ViewBuilder button: () -> Button) {
        self.car = car
        self.button = button()
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: car.decorativeIconName)
                .symbolVariant(.fill)
                .font(.largeTitle)
            VStack(alignment: .leading) {
                Text(verbatim: car.displayName)
                    .font(.callout)
                Text(verbatim: car.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            button
                .font(.callout.bold())
                .frame(
                    width: SharedLayoutConstants.buyButtonWidth,
                    height: SharedLayoutConstants.buyButtonHeight
                )
                .foregroundStyle(.white)
        }
        
    }
}

private struct CarProductViewStyle: ProductViewStyle {
    @Binding var selectedCar: Car
    let isPurchasing: Bool

    @Environment(\.ownedCars) private var ownedCars

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        Group {
            if let product = configuration.product,
               let car = Car(product.id) {
                GarageRow(car: car) {
                    let hasCurrentEntitlement = ownedCars.contains(car) || configuration.hasCurrentEntitlement
                    Button {
                        if hasCurrentEntitlement {
                            withAnimation {
                                selectedCar = car
                            }
                        } else {
                            configuration.purchase()
                        }
                    } label: {

                    }
                    .buttonStyle(
                        .garageRowButton(
                            hasCurrentEntitlement: hasCurrentEntitlement,
                            car: car,
                            displayPrice: product.displayPrice
                        )
                    )
                    .disabled(isPurchasing && !hasCurrentEntitlement)
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Spacer()
                }
            }
        }
    }
}

private extension ProductViewStyle where Self == CarProductViewStyle {
    static func car(selectedCar: Binding<Car>, isPurchasing: Bool) -> Self {
        .init(selectedCar: selectedCar, isPurchasing: isPurchasing)
    }
}

private struct GarageRowButtonStyle: ButtonStyle {
    let hasCurrentEntitlement: Bool
    let car: Car
    let displayPrice: String?

    @Environment(\.selectedCar) private var selectedCar

    private var backgroundStyle: AnyShapeStyle {
        if hasCurrentEntitlement {
            car == selectedCar ? AnyShapeStyle(.green) : AnyShapeStyle(.gray.secondary)
        } else {
            AnyShapeStyle(.tint)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        Group {
            if hasCurrentEntitlement {
                Image(systemName: ImageNameConstants.Garage.purchasedCarButtonIcon)
                    .font(.title3.weight(.semibold))
                    .padding(.vertical, 8)
            } else if let displayPrice {
                Text(verbatim: displayPrice)
                    .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(backgroundStyle, in: .capsule(style: .circular))
    }
}

private extension ButtonStyle where Self == GarageRowButtonStyle {
    static func garageRowButton(
        hasCurrentEntitlement: Bool,
        car: Car,
        displayPrice: String? = nil
    ) -> Self {
        .init(
            hasCurrentEntitlement: hasCurrentEntitlement,
            car: car,
            displayPrice: displayPrice
        )
    }
}
