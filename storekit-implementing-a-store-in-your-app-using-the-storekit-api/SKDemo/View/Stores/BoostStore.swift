/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A store that sells boosts.
*/

import StoreKit
import SwiftUI

// A store that is implemented using StoreKit views.
struct BoostStore: View {
    @Binding var isPurchasing: Bool

    var body: some View {
        CarItemStore(carItem: .boosts) { product in
            CustomProductView(productID: product.id, isPurchasing: isPurchasing)
        }
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

private struct CustomProductView: View {
    let productID: Product.ID
    let isPurchasing: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ProductView(id: productID) {
            Image(systemName: ImageNameConstants.BoostStore.productViewIcon)
                .font(.system(size: SharedLayoutConstants.productIconFontSize))
                .symbolVariant(.fill)
                .foregroundStyle(.tint, .tint.secondary)
                .tint(isPurchasing ? .gray : .accentColor)
                .overlay(alignment: .bottomLeading) {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.9))
                            .background(.ultraThinMaterial, in: .circle)
                            .compositingGroup()
                            .opacity(isPurchasing ? 0.5 : 0.7)
                            .frame(width: 30)
                        if let packCount = productID.description.components(separatedBy: ".").last {
                            Text(verbatim: packCount)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(colorScheme == .light ? .white : .black)
                        }
                    }
                    .offset(x: -3, y: 8)
                }
        }
        .productViewStyle(.boost(isPurchasing: isPurchasing))
    }
}

private struct BoostProductViewStyle: ProductViewStyle {
    let isPurchasing: Bool

    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: SharedLayoutConstants.defaultVerticalSpacing) {
            switch configuration.state {
            case .success(let product):
                Spacer(minLength: .zero)
                configuration.icon
                    .layoutPriority(3)
                Spacer(minLength: SharedLayoutConstants.productIconBottomSpacing)
                    .layoutPriority(1)
                displayNameLabel(for: product)
                    .layoutPriority(3)
                descriptionLabel(for: product)
                    .layoutPriority(3)
                Spacer()
                    .layoutPriority(2)
                buyButton(for: product, action: configuration.purchase)
                    .layoutPriority(3)
            case _:
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                Spacer()
            }
        }
        .multilineTextAlignment(.center)
    }

    private func displayNameLabel(for product: Product) -> some View {
        Text(verbatim: product.displayName)
            .lineLimit(2)
            .font(.headline.weight(.semibold))
    }

    private func descriptionLabel(for product: Product) -> some View {
        Text(verbatim: product.description)
            .lineLimit(2, reservesSpace: true)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func buyButton(for product: Product, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: product.displayPrice)
        }
        .buttonStyle(.boostProductViewButtonStyle)
        .frame(
            width: SharedLayoutConstants.buyButtonWidth,
            height: SharedLayoutConstants.buyButtonHeight
        )
        .foregroundStyle(.tint)
        .disabled(isPurchasing)
    }
}

private extension ProductViewStyle where Self == BoostProductViewStyle {
    static func boost(isPurchasing: Bool) -> Self { .init(isPurchasing: isPurchasing) }
}

private struct BoostProductViewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .opacity(
                configuration.isPressed ? SharedLayoutConstants.buyButtonPressedOpacity : SharedLayoutConstants.buyButtonIdleOpacity
            )
            .animation(
                .easeInOut(duration: SharedLayoutConstants.buyButtonPressAnimationDuration),
                value: configuration.isPressed
            )
            .padding(SharedLayoutConstants.buyButtonLabelPadding)
            .background(.background.secondary, in: .capsule(style: .circular))
    }
}

private extension ButtonStyle where Self == BoostProductViewButtonStyle {
    static var boostProductViewButtonStyle: Self { .init() }
}
