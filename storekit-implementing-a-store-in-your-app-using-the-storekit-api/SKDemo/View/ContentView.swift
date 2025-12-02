/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main screen of the app.
*/

import SKDemoServer
import StoreKit
import SwiftUI

struct ContentView: View {
    @Environment(\.skDemoPlusStatus) private var skDemoPlusStatus

    @State private var garageIsPresented: Bool = false
    @State private var subscriptionStoreIsPresented: Bool = false

    @State private var selectedCar: Car = CustomerEntitlements.freeCar
    @State private var selectedCarItem: Car.Item?

    @State private var isPurchasing: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    SelectedCarView()
                    CustomDivider()
                        .padding(.vertical)
                    ContentGrid(
                        subscriptionStoreIsPresented: $subscriptionStoreIsPresented,
                        selectedCarItem: $selectedCarItem,
                        isPurchasing: $isPurchasing
                    )
                }
            }
            .contentMargins(10)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    GarageButton(garageIsPresented: $garageIsPresented)
                }
            }
            .navigationDestination(item: $selectedCarItem) { carItem in
                carItem.storeView(isPurchasing: $isPurchasing)
            }
            .navigationTitle("SKDemo")
        }
        .sheet(isPresented: $subscriptionStoreIsPresented) {
            SubscriptionStore(isPurchasing: $isPurchasing)
                .navigationBarBackButtonHidden()
        }
        .sheet(isPresented: $garageIsPresented) {
            Garage(selectedCar: $selectedCar, isPurchasing: $isPurchasing)
                .presentationDetents([.fraction(1 / 2)])
        }
        .scrollIndicators(.hidden)
        .environment(\.selectedCar, selectedCar)
    }
}

private struct GarageButton: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var garageIsPresented: Bool

    var body: some View {
        Button {
            withAnimation {
                garageIsPresented = true
            }
        } label: {
            Image(
                systemName: garageIsPresented ?
                ImageNameConstants.ContentView.garageDoorOpen :
                    ImageNameConstants.ContentView.garageDoorClosed
            )
            .contentTransition(.symbolEffect(.replace, options: .speed(2)))
            .foregroundStyle(colorScheme == .dark ? .white : .black, .tint)
        }
        .buttonStyle(.plain)
    }
}

private struct ContentGrid: View {
    @Binding var subscriptionStoreIsPresented: Bool
    @Binding var selectedCarItem: Car.Item?
    @Binding var isPurchasing: Bool

    @Environment(\.skDemoPlusStatus) private var skDemoPlusStatus

    private let carItems: [Car.Item] = Car.Item.allCases
    private let columns: Int = 2
    private var rows: Int {
        (carItems.count + columns - 1) / columns
    }

    var body: some View {
        Grid(
            horizontalSpacing: SharedLayoutConstants.gridSpacing,
            verticalSpacing: SharedLayoutConstants.gridSpacing
        ) {
            // Only show the SubscriptionOfferView if the user is unsubscribed
            // (i.e. has never subscribed or no longer has an active subscription).
            if skDemoPlusStatus == .unsubscribed {
                SubscriptionOfferView(groupID: Server.shared.skDemoPlusGroupID, visibleRelationship: .upgrade)
                    .subscriptionOfferViewDetailAction {
                        subscriptionStoreIsPresented = true
                    }
                    .productDescription(.visible)
                    .subscriptionOfferViewStyle(.skDemoPlus)
                    .disabled(isPurchasing)
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
            PremiumFeatureCard()
            ForEach(0..<rows, id: \.self) { rowIndex in
                GridRow {
                    ForEach(0..<columns, id: \.self) { columnIndex in
                        let itemIndex = rowIndex * columns + columnIndex
                        if itemIndex < carItems.count {
                            let carItem = carItems[itemIndex]
                            Button {
                                selectedCarItem = carItem
                            } label: {
                                CarItemCard(item: carItem)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct SKDemoPlusSubscriptionOfferViewStyle: SubscriptionOfferViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            switch configuration.state {
            case .success:
                SubscriptionOfferView(configuration)
            case _:
                ProgressView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            .ultraThickMaterial,
            in: .rect(cornerRadius: SharedLayoutConstants.cardCornerRadius, style: .circular)
        )
    }
}

private extension SubscriptionOfferViewStyle where Self == SKDemoPlusSubscriptionOfferViewStyle {
    static var skDemoPlus: Self { .init() }
}
