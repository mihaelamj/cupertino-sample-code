/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A store that sells fuel.
*/

import StoreKit
import SwiftUI

// A store that is implemented using SwiftUI primitives.
struct FuelStore: View {
    @Binding var isPurchasing: Bool

    var body: some View {
        CarItemStore(carItem: .fuel) { product in
            SwiftUIMerchandisingView(product: product, isPurchasing: $isPurchasing)
        }
    }
}

private struct SwiftUIMerchandisingView: View {
    let product: Product
    @Binding var isPurchasing: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.purchase) private var purchaseAction

    var body: some View {
        VStack(spacing: SharedLayoutConstants.defaultVerticalSpacing) {
            Spacer(minLength: .zero)
            merchandisingIcon
                .layoutPriority(3)
            Spacer(minLength: SharedLayoutConstants.productIconBottomSpacing)
                .layoutPriority(1)
            displayNameLabel
                .layoutPriority(3)
            descriptionLabel
                .layoutPriority(3)
            Spacer()
                .layoutPriority(2)
            buyButton
                .layoutPriority(3)
        }
        .multilineTextAlignment(.center)
    }

    private var merchandisingIcon: some View {
        Image(systemName: ImageNameConstants.FuelStore.merchandisingViewIcon)
            .font(.system(size: SharedLayoutConstants.productIconFontSize))
            .symbolVariant(.fill)
            .foregroundStyle(.tint, .tint.secondary)
            .tint(isPurchasing ? .gray : .accentColor)
            .overlay {
                if let octaneRating = product.id.components(separatedBy: ".").last {
                    Text(verbatim: octaneRating)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .offset(x: -2.5, y: 5)
                }
            }
    }

    private var displayNameLabel: some View {
        Text(verbatim: product.displayName)
            .lineLimit(2)
            .font(.headline.weight(.semibold))
    }

    private var descriptionLabel: some View {
        Text(verbatim: product.description)
            .lineLimit(2, reservesSpace: true)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private var buyButton: some View {
        Button(action: purchase) {
            Text(verbatim: product.displayPrice)
        }
        .buttonStyle(.merchandisingViewButtonStyle)
        .frame(
            width: SharedLayoutConstants.buyButtonWidth,
            height: SharedLayoutConstants.buyButtonHeight
        )
        .foregroundStyle(.tint)
        .disabled(isPurchasing)
    }

    private func purchase() {
        isPurchasing = true
        Task {
            defer { isPurchasing = false }
            if let purchaseResult = try? await purchaseAction(product) {
                await Store.shared.process(purchaseResult: purchaseResult)
            }
        }
    }
}

private struct MerchandisingViewButtonStyle: ButtonStyle {
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

private extension ButtonStyle where Self == MerchandisingViewButtonStyle {
    static var merchandisingViewButtonStyle: Self { .init() }
}
