/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The detail view for a given flight leg that displays weather data.
*/

import SwiftUI
import WeatherKit

struct FlightLegDetail: View {
    var leg: FlightLeg
    @Environment(\.calendar) private var calendar
    @StateObject private var weatherData = WeatherData.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                FlightLegDetailBanner(
                    leg: leg,
                    weather: destinationWeather)
                FlightLegDetailSection(
                    info: departureInfo,
                    weather: originWeather,
                    tintColor: Color(leg.color))
                FlightLegDetailSection(
                    info: arrivalInfo,
                    weather: destinationWeather,
                    tintColor: Color(leg.color))
            }
            .backgroundStyle(.background)
            .environmentObject(weatherData)
        }
        .ignoresSafeArea(edges: .top)
        .task {
            Task.detached { @MainActor in
                await weatherData.weather(for: leg.origin)
                await weatherData.weather(for: leg.destination)
            }
        }
    }
    
    var originWeather: CurrentWeather? {
        weatherData[airport: leg.origin.id]
    }
    
    var destinationWeather: CurrentWeather? {
        weatherData[airport: leg.destination.id]
    }
    
    var departureInfo: FlightInfo {
        FlightInfo(date: leg.departure, airport: leg.origin)
    }
    
    var arrivalInfo: FlightInfo {
        FlightInfo(date: leg.arrival, airport: leg.destination)
    }
}

struct FlightLegDetail_Previews: PreviewProvider {
    static var previews: some View {
        FlightLegDetail(leg: .sfoToMia)
    }
}
