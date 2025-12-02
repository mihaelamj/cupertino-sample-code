/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The header view for a flight leg row.
*/

import SwiftUI

struct FlightLegRowHeader: View {
    var alignment: HorizontalAlignment
    var title: String
    var icon: Icon
    var airport: Airport
    var date: Date
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Label(title, systemImage: icon.rawValue)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .labelStyle(AlignmentLabelStyle(alignment: alignment))
            
            VStack(alignment: alignment) {
                Text(airport.code)
                    .font(.largeTitle)
                    .bold()
                
                Text(airport.city)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: -2)
            }
            .alignmentGuide(.flightLegArrow) { dimensions in
                dimensions[VerticalAlignment.center]
            }
            
            Text(date, format: dateFormat)
                .fontWeight(.medium)

            Text(date, style: .time)
                .font(.callout)
                .fontWeight(.medium) +
            Text(" ") +
            Text(date, format: timeZoneFormat)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    var dateFormat: Date.FormatStyle {
        Date.FormatStyle().weekday(.abbreviated).month(.abbreviated).day()
    }
    
    var timeZoneFormat: Date.FormatStyle {
        Date.FormatStyle().timeZone()
    }
}

extension FlightLegRowHeader {
    enum Icon: String {
        case arrival = "airplane.arrival"
        case calendar
        case departure = "airplane.departure"
        case mapPin = "mappin.and.ellipse"
    }
}

private struct AlignmentLabelStyle: LabelStyle {
    var alignment: HorizontalAlignment
    
    func makeBody(configuration: Configuration) -> some View {
        if alignment == .trailing {
            HStack {
                configuration.title
                configuration.icon
            }
        } else {
            HStack {
                configuration.icon
                configuration.title
            }
        }
    }
}

struct FlightLegRowHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FlightLegRowHeader(
                alignment: .leading,
                title: "Departure",
                icon: .departure,
                airport: .sfo,
                date: .now)
            FlightLegRowHeader(
                alignment: .trailing,
                title: "Arrival",
                icon: .arrival,
                airport: .mia,
                date: .now.addingTimeInterval(60 * 60 * 6)) // +6 hours
        }
    }
}
