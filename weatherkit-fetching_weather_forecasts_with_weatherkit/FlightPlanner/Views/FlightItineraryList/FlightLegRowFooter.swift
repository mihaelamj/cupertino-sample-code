/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The footer view for a flight leg row.
*/

import SwiftUI

private let formatter = RelativeDateTimeFormatter()

struct FlightLegRowFooter: View {
    var alignment: HorizontalAlignment
    var leg: FlightLeg
    
    private let spacing = CGFloat(2)
    
    var body: some View {
        switch alignment {
        case .leading:
            leadingContent
        case .trailing:
            trailingContent
        default:
            centerContent
        }
    }
    
    var leadingContent: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text("Flight")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(leg.designator)
                .fontWeight(.medium)
        }
    }
    
    var centerContent: some View {
        VStack(spacing: spacing) {
            Text("Gate")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(leg.gate)
                .fontWeight(.medium)
        }
    }
    
    var trailingContent: some View {
        VStack(alignment: .trailing, spacing: spacing) {
            Text("Duration")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatter.localizedString(fromTimeInterval: leg.duration))
                .fontWeight(.medium)
        }
    }
}

struct FlightLegRowFooter_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FlightLegRowFooter(alignment: .leading, leg: .sfoToMia)
            FlightLegRowFooter(alignment: .center, leg: .miaToPmi)
            FlightLegRowFooter(alignment: .trailing, leg: .sfoToMia)
        }
    }
}
