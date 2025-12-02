/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The row that displays flight leg information for a section of flight segments
 in the flight itinerary list.
*/

import SwiftUI

struct FlightLegRow: View {
    var leg: FlightLeg
    var isSelected: Bool = false
    
    var body: some View {
        ZStack(alignment: .arrowBottom) {
            FlightLegRowFooter(alignment: .center, leg: leg)
                .alignmentGuide(.arrow) { dimensions in
                    dimensions[HorizontalAlignment.center]
                }
            VStack(spacing: 8) {
                HStack(alignment: .flightLegArrow) {
                    FlightLegRowHeader(
                        alignment: .leading,
                        title: "Departure",
                        icon: .departure,
                        airport: leg.origin,
                        date: leg.departure)
                    Spacer()
                    FlightLegArrow(color: leg.color)
                    Spacer()
                    FlightLegRowHeader(
                        alignment: .trailing,
                        title: "Arrival",
                        icon: .arrival,
                        airport: leg.destination,
                        date: leg.arrival)
                }
                HStack {
                    FlightLegRowFooter(alignment: .leading, leg: leg)
                    Spacer()
                    FlightLegRowFooter(alignment: .trailing, leg: leg)
                }
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fillStyle)
        }
    }
    
    var fillStyle: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(.clear)
        } else {
            return AnyShapeStyle(.background)
        }
    }
}

extension Alignment {
    static let arrowBottom = Alignment(horizontal: .arrow, vertical: .bottom)
}

extension HorizontalAlignment {
    private struct FlightListLegRowArrow: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat {
            dimensions[HorizontalAlignment.center]
        }
    }
    
    fileprivate static let arrow = HorizontalAlignment(FlightListLegRowArrow.self)
}

struct FlightListLegRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FlightLegRow(leg: .sfoToMia, isSelected: false)
            FlightLegRow(leg: .sfoToMia, isSelected: true)
            FlightLegRow(leg: .miaToPmi, isSelected: false)
            FlightLegRow(leg: .miaToPmi, isSelected: true)
        }
    }
}
