/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An entry point to an in-app store that sells car items.
*/

import SwiftUI

struct CarItemCard: View {
    let item: Car.Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: SharedLayoutConstants.defaultVerticalSpacing) {
                Text(verbatim: item.title)
                    .font(.callout.weight(.semibold))
                if let caption = item.caption {
                    Text(verbatim: caption)
                        .font(.caption.weight(.thin))
                        .brightness(0.8)
                }
                Spacer(minLength: .zero)
            }
            .multilineTextAlignment(.leading)
            Spacer()
            Image(systemName: item.decorativeIconName)
                .font(.title)
        }
        .foregroundStyle(.white)
        .frame(height: 60)
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background {
            ZStack {
                ForEach(0..<3) { idx in
                    var fillShapeStyle: AnyShapeStyle {
                        switch idx {
                        case 1:
                            AnyShapeStyle(.secondary)
                        case 2:
                            AnyShapeStyle(.tertiary)
                        case _:
                            AnyShapeStyle(.primary)
                        }
                    }

                    RoundedRectangle(
                        cornerRadius: SharedLayoutConstants.cardCornerRadius,
                        style: .circular
                    )
                    .fill(fillShapeStyle)
                    .offset(y: CGFloat(idx).scaled(by: 4))
                    .padding(.horizontal, CGFloat(idx).scaled(by: 4))
                }
            }
            .foregroundStyle(.tint)
        }
    }
}
