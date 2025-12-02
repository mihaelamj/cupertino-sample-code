/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A linear progress view that displays its percentage at the leading edge.
*/

import SwiftUI

struct LinearReadingProgressView: View {
    var value: Double
    var isSelected: Bool
    
    var body: some View {
        let style = LinearReadingProgressViewStyle(isSelected: isSelected)
        ProgressView(value: value)
            .progressViewStyle(style)
            .frame(width: 125)
    }
}

private struct LinearReadingProgressViewStyle: ProgressViewStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        let value = configuration.fractionCompleted ?? 0
        return HStack {
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .foregroundStyle(.tertiary)
                    .overlay {
                        GeometryReader { proxy in
                            Capsule(style: .continuous)
                                .frame(width: proxy.size.width * value)
                                .foregroundStyle(foregroundStyle(for: value))
                        }
                    }
            }
            .frame(height: 4)
            Text(Int(value * 100), format: .percent)
        }
        
        func foregroundStyle(for value: Double) -> some ShapeStyle {
            if isSelected {
                return AnyShapeStyle(.background)
            } else if value == 1 {
                return AnyShapeStyle(.green)
            } else {
                return AnyShapeStyle(.tint)
            }
        }
    }
}

struct LinearReadingProgressView_Previews: PreviewProvider {
    static var previews: some View {
        LinearReadingProgressView(value: 0.5, isSelected: true)
        LinearReadingProgressView(value: 0.5, isSelected: false)
    }
}
