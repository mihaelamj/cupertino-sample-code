/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The premium feature that unlocks when the user subscribes to the app's service.
*/

import SwiftUI

struct PremiumFeatureCard: View {
    @Environment(\.skDemoPlusStatus) private var skDemoPlusStatus

    private var hidePaidContent: Bool {
        skDemoPlusStatus == .unsubscribed
    }

    var body: some View {
        Button {
            // Intentionally no-op.
            // This is where you display the premium content
            // they're entitled to after subscribing to your service.
        } label: {
            ZStack {
                VStack(alignment: .leading, spacing: SharedLayoutConstants.defaultVerticalSpacing) {
                    HStack {
                        VStack(alignment: .leading, spacing: SharedLayoutConstants.defaultVerticalSpacing) {
                            Text(verbatim: "Race")
                                .font(.title.bold())
                            Text(verbatim: "Take your car to the track!")
                                .fontWeight(.thin)
                                .brightness(0.8)
                        }
                        Spacer()
                        Image(systemName: ImageNameConstants.PremiumFeatureCard.gauge)
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(verbatim: "Best Time: 0:00:00")
                        .font(.headline.weight(.semibold))
                }
                .multilineTextAlignment(.leading)
                .foregroundStyle(.white)
                .frame(height: 120)
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(
                    .tint,
                    in: .rect(cornerRadius: SharedLayoutConstants.cardCornerRadius, style: .circular)
                )
                if hidePaidContent {
                    RoundedRectangle(
                        cornerRadius: SharedLayoutConstants.cardCornerRadius,
                        style: .circular
                    )
                    .fill(.background.quaternary)
                    .opacity(0.7)

                    PremiumFeatureBadge()
                }
            }
        }
        .disabled(hidePaidContent)
    }
}

private struct PremiumFeatureBadge: View {
    var body: some View {
        HStack {
            Image(systemName: ImageNameConstants.PremiumFeatureCard.lock)
            Text(verbatim: "Premium Feature")
        }
        .foregroundStyle(.secondary)
        .padding(20)
        .background(
            .background.shadow(.drop(color: .black.opacity(0.15), radius: 6, y: 2)),
            in: .capsule
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
