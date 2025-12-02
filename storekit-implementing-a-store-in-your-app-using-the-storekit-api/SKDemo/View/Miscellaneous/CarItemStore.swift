/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The shared implementation of a CarItem in-app store.
*/

import StoreKit
import SwiftUI

struct CarItemStore<MerchandisingView: View>: View {
    private let carItem: Car.Item
    private let merchandisingView: (Product) -> MerchandisingView

    init(
        carItem: Car.Item,
        @ViewBuilder merchandisingView: @escaping (Product) -> MerchandisingView
    ) {
        self.carItem = carItem
        self.merchandisingView = merchandisingView
    }

    private var navigationTitle: String {
        switch carItem {
        case .boosts:
            "Boost Store"
        case .fuel:
            "Fuel Store"
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                StoreHeader(carItem: carItem)
                ContentGrid(carItem: carItem, merchandisingView: merchandisingView)
                    .padding(.horizontal)
            }
        }
        .padding(.top)
        .scrollIndicators(.hidden)
        .navigationTitle(navigationTitle)
        .background {
            BackgroundGradient()
                .ignoresSafeArea()
        }
    }
}

private struct ContentGrid<MerchandisingView: View>: View {
    private let carItem: Car.Item
    private let merchandisingView: (Product) -> MerchandisingView

    init(
        carItem: Car.Item,
        @ViewBuilder merchandisingView: @escaping (Product) -> MerchandisingView
    ) {
        self.carItem = carItem
        self.merchandisingView = merchandisingView
    }

    private var products: [Product] {
        switch carItem {
        case .boosts:
            Store.shared.boosts
        case .fuel:
            Store.shared.fuel
        }
    }

    private let columns: Int = 2
    private var rows: Int {
        (products.count + columns - 1) / columns
    }

    var body: some View {
        Grid(verticalSpacing: SharedLayoutConstants.gridSpacing) {
            ForEach(0..<rows, id: \.self) { rowIndex in
                GridRow {
                    ForEach(0..<columns, id: \.self) { columnIndex in
                        let itemIndex = rowIndex * columns + columnIndex
                        if itemIndex < products.count {
                            merchandisingView(products[itemIndex])
                                .padding(.vertical)
                                .padding(.horizontal, SharedLayoutConstants.productViewHorizontalPadding)
                                .frame(height: SharedLayoutConstants.productViewHeight)
                                .containerRelativeFrame(.horizontal) { length, _ in
                                    length *
                                    SharedLayoutConstants.productViewContainerRelativeWidthRatio -
                                    SharedLayoutConstants.contentMargins
                                }
                                .background(
                                    .thinMaterial,
                                    in: .rect(cornerRadius: SharedLayoutConstants.cardCornerRadius, style: .circular)
                                )
                        }
                    }
                }
            }
        }
    }
}

private struct StoreHeader: View {
    let carItem: Car.Item

    var body: some View {
        Image(systemName: carItem.decorativeIconName)
            .font(.system(size: SharedLayoutConstants.storeHeaderIconFontSize))
            .symbolVariant(.fill)
            .foregroundStyle(.tint, .tint.secondary)
        Divider()
            .frame(height: SharedLayoutConstants.storeHeaderDividerHeight)
            .padding(.vertical)
    }
}

private struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                .black,
                .gray,
                .gray,
                .white
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}
