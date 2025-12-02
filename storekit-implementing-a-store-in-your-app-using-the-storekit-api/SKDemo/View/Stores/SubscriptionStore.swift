/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The subscription paywall.
*/

import SKDemoServer
import StoreKit
import SwiftUI

struct SubscriptionStore: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPurchasing: Bool

    var body: some View {
        SubscriptionStoreView(groupID: Server.shared.skDemoPlusGroupID) {
            FamilySharingSubscriptionOptionGroupSet()
        }
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStoreControlIcon { product, subscriptionInfo in
            Image(systemName: decorativeIconSystemName(for: subscriptionInfo))
                .symbolVariant(.fill)
                .foregroundStyle(colorScheme == .dark ? .white : .black, .tint)
        }
        .navigationBarTitleDisplayMode(.inline)
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

    private func decorativeIconSystemName(for subscription: Product.SubscriptionInfo) -> String {
        if subscription.groupLevel == 2 {
            ImageNameConstants.SubscriptionStore.premiumPlanIcon
        } else if subscription.groupLevel == 3 {
            ImageNameConstants.SubscriptionStore.proPlanIcon
        } else {
            ImageNameConstants.SubscriptionStore.standardPlanIcon
        }
    }
}

private struct FamilySharingSubscriptionOptionGroupSet: StoreContent {
    private enum SubscriptionOptionGroup: String, Hashable {
        case individual
        case family

        var description: String {
            rawValue.capitalized
        }
    }

    var body: some StoreContent {
        SubscriptionOptionGroupSet(
            groupedBy: { product in
                product.isFamilyShareable ? SubscriptionOptionGroup.family : .individual
            },
            label: { group in
                Text(verbatim: group.description)
            },
            marketingContent: { _ in
                SKDemoPlusMarketingContent()
            }
        )
    }
}

private struct SKDemoPlusMarketingContent: View {
    var body: some View {
        VStack(alignment: .center, spacing: 60) {
            Image(systemName: ImageNameConstants.SubscriptionStore.marketingContentIcon)
                .font(.system(size: 70))
                .foregroundStyle(.tint, .tint.secondary)
            VStack(alignment: .leading, spacing: 14) {
                Text("SKDemo+")
                    .font(.title.bold())
                Text("Unlock exclusive content and member-only discounts on parts and services")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 350)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical)
        .padding(.top, 60)
        .multilineTextAlignment(.leading)
    }
}
