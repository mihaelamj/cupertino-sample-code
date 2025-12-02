/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that shows the edit sliders.
*/

import SwiftUI

extension Adjustment.Identifier {
    var symbol: String {
        switch self {
        case .contrast:
            return "circle.righthalf.filled"
        case .exposure:
            return "camera.aperture"
        case .saturation:
            return "camera.filters"
        case .sepia:
            return "line.3.crossed.swirl.circle.fill"
        }
    }
}

@MainActor
struct AdjustView: View {

    @Bindable var asset: EditedAsset

    @State var adjustmentIdx: Int = 0
    @State var adjustmentId: Adjustment.Identifier = .exposure {
        didSet {
            self.adjustmentIdx = asset.adjustments.firstIndex(where: { $0.id == adjustmentId }) ?? 0
        }
    }

    var body: some View {
        VStack(spacing: 4.0) {
            HStack {
                ForEach($asset.adjustments) { $adjustment in
                    Button {
                        if adjustmentId == adjustment.id {
                            adjustment.enabled.toggle()
                        } else {
                            self.adjustmentId = adjustment.id
                        }
                    } label: {
                        Image(systemName: adjustment.id.symbol)
                            .font(.system(size: 20, weight: .regular))
                            .symbolRenderingMode(.monochrome)
                            .padding(4.0)
                            .overlay(Circle().stroke(lineWidth: 1.0))
                            .foregroundColor(adjustment.id == adjustmentId ? Color.accentColor : Color.primary)
                            .opacity(adjustment.enabled ? 1.0 : 0.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            AdjustmentView(adjustment: $asset.adjustments[adjustmentIdx])
                .frame(maxWidth: 250)
                .disabled(asset.showOriginal)
        }
    }
}

struct AdjustmentView: View {

    @Binding var adjustment: Adjustment

    var body: some View {
        VStack(spacing: 2.0) {
            Text(adjustment.id.rawValue)
            Slider(value: $adjustment.value, in: adjustment.id.range) { _ in
                adjustment.enabled = true
            }
            .controlSize(.small)
            .opacity(adjustment.enabled ? 1.0 : 0.5)
        }
        .font(.body.smallCaps())
        .foregroundColor(adjustment.enabled ? .primary : .secondary)
    }
}
