/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The arrow icon that displays between airports for a given flight leg.
*/

import SwiftUI

struct FlightLegArrow: View {
    var color: FlightSegment.Color
    
    var body: some View {
        Circle()
            .fill(Color(color))
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: "arrow.right")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(Color(.systemBackground))
                    .padding()
            }
            .alignmentGuide(.flightLegArrow) { dimensions in
                dimensions[VerticalAlignment.center]
            }
    }
}

extension VerticalAlignment {
    private struct FlightLegArrow: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat {
            dimensions[VerticalAlignment.center]
        }
    }

    static let flightLegArrow = VerticalAlignment(FlightLegArrow.self)
}

struct FlightLegArrow_Previews: PreviewProvider {
    static var previews: some View {
        FlightLegArrow(color: .random)
    }
}
