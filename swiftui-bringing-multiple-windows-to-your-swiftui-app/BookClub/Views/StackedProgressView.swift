/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A vertically stacked progress view that displays its percentage at the
 bottom edge.
*/

import SwiftUI

struct StackedProgressView: View {
    var value: Double

    var body: some View {
        ProgressView(value: value)
            .progressViewStyle(StackedProgressViewStyle())
            .frame(width: 100)
    }
}

private struct StackedProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let value = configuration.fractionCompleted ?? 0
        return VStack {
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
            if value == 1 {
                return AnyShapeStyle(.green)
            } else {
                return AnyShapeStyle(.tint)
            }
        }
    }
}

struct StackedProgressView_Previews: PreviewProvider {
    static var previews: some View {
        StackedProgressView(value: 0.5)
    }
}
