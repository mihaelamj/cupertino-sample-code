/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The detail banner view for a given flight leg that displays weather data
 for the destination.
*/

import SwiftUI
import WeatherKit

struct FlightLegDetailBanner: View {
    @Environment(\.calendar) private var calendar
    var leg: FlightLeg
    var weather: CurrentWeather?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            image
            VStack(alignment: .weatherSymbol, spacing: 6) {
                headlines
                subheadlines
            }
            .padding(20)
            .foregroundStyle(.background.shadow(.drop(radius: 2)))
            .background {
                Color(leg.color)
                    .shadow(radius: 4, y: -4)
            }
        }
    }
    
    var image: some View {
        Image(leg.destination.imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 300)
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [Color(.systemBackground), .clear, .clear],
                    startPoint: .top,
                    endPoint: .bottom)
            }
    }
    
    var headlines: some View {
        HStack {
            Text(title)
                .font(.headline)
                .lineLimit(2, reservesSpace: true)
            Spacer()
            Group {
                if let systemName = weather?.symbolName {
                    Text(Image(systemName: systemName))
                } else {
                    Text("--")
                }
            }
            .font(.title)
            .alignmentGuide(.weatherSymbol) { dimensions in
                dimensions[HorizontalAlignment.center]
            }
        }
        .fontWeight(.bold)
    }
    
    var title: String {
        let origin = leg.origin.locationDescription
        let destination = leg.destination.locationDescription
        return "Flight from \(origin), \nto \(destination)"
    }
    
    var subheadlines: some View {
        HStack {
            Text(hasSameDayFlights ? flightDate : flightDateRange)
            Spacer()
            Text(weather?.temperature.formatted() ?? "--")
                .alignmentGuide(.weatherSymbol) { dimensions in
                    dimensions[HorizontalAlignment.center]
                }
        }
        .font(.subheadline)
    }
    
    var hasSameDayFlights: Bool {
        calendar.isDate(departure, inSameDayAs: arrival)
    }
    
    var flightDate: LocalizedStringKey {
        "\(departure, style: .date)"
    }
    
    var flightDateRange: LocalizedStringKey {
        "\(departure, style: .date) – \(arrival, style: .date)"
    }
    
    var departure: Date {
        leg.departure
    }
    
    var arrival: Date {
        leg.arrival
    }
}

extension HorizontalAlignment {
    private struct WeatherSymbol: AlignmentID {
        static func defaultValue(in dimension: ViewDimensions) -> CGFloat {
            dimension[HorizontalAlignment.center]
        }
    }

    fileprivate static let weatherSymbol: HorizontalAlignment = {
        HorizontalAlignment(WeatherSymbol.self)
    }()
}

struct FlightLegDetailBanner_Previews: PreviewProvider {
    static var previews: some View {
        FlightLegDetailBanner(leg: .sfoToMia)
    }
}
