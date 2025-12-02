/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The detail section view for a given flight leg that displays a grid
 of weather forecast data.
*/

import SwiftUI
import WeatherKit

struct FlightLegDetailSection: View {
    var info: FlightInfo
    var weather: CurrentWeather?
    var tintColor: Color
    @Environment(\.calendar) private var calendar
    @EnvironmentObject private var weatherData: WeatherData
    
    var body: some View {
        VStack(alignment: .leading) {
            dateTime
            HStack(alignment: .flightLegDetailAirplane) {
                airplane
                VStack(alignment: .leading) {
                    header
                    Spacer(minLength: 24)
                    FlightLegDetailWeatherGrid(
                        flightInfo: info,
                        forecastInfo: forecastInfo)
                    Spacer()
                }
                Spacer()
            }
        }
        .padding()
        .foregroundStyle(.secondary)
        .task {
            Task.detached { @MainActor in
                await weatherData.hourlyForecast(for: info.airport)
                await weatherData.dailyForecast(for: info.airport)
            }
        }
    }
    
    var dateTime: some View {
        HStack {
            Text(info.date, formatter: Self.dateFormatter)
            Text(info.date, style: .time)
        }
        .padding(.bottom, 4)
    }
    
    static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()
    
    var airplane: some View {
        VStack {
            Image(systemName: "airplane")
                .foregroundColor(tintColor)
                .rotationEffect(.degrees(90))
                .font(.title)
                .alignmentGuide(.flightLegDetailAirplane) { dimensions in
                    dimensions[VerticalAlignment.center]
                }
            Spacer(minLength: 24)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .frame(width: 2, height: 160)
                .overlay(alignment: .bottom) {
                    Circle()
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 10, height: 10)
                    Circle()
                        .fill(tintColor)
                        .frame(width: 6, height: 6)
                }
        }
    }
    
    var header: some View {
        Text(info.airport.code)
            .font(.title)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .alignmentGuide(.flightLegDetailAirplane) { dimensions in
                dimensions[VerticalAlignment.center]
            }
    }
    
    var forecastInfo: [FlightForecastInfo] {
        hourlyForecastInfo.isEmpty ? dailyForecastInfo : hourlyForecastInfo
    }
    
    var dailyForecast: Forecast<DayWeather>? {
        weatherData[airport: info.airport.id]
    }
    
    var hourlyForecast: Forecast<HourWeather>? {
        weatherData[airport: info.airport.id]
    }
    
    var dailyForecastInfo: [FlightForecastInfo] {
        guard let dailyForecast = dailyForecast else { return [] }
        return dailyForecast.forecast
            .filter { $0.date >= info.date }
            .prefix(7)
            .map(FlightForecastInfo.init)
    }
    
    var hourlyForecastInfo: [FlightForecastInfo] {
        guard let hourlyForecast = hourlyForecast else { return [] }
        return hourlyForecast.forecast
            .filter { $0.date >= info.date }
            .prefix(7)
            .map(FlightForecastInfo.init)
    }
}

extension VerticalAlignment {
    private struct FlightLegDetailAirplane: AlignmentID {
        static func defaultValue(in dimension: ViewDimensions) -> CGFloat {
            dimension[VerticalAlignment.center]
        }
    }

    fileprivate static let flightLegDetailAirplane: VerticalAlignment = {
        VerticalAlignment(FlightLegDetailAirplane.self)
    }()
}

struct FlightLegDetailSection_Previews: PreviewProvider {
    static var previews: some View {
        FlightLegDetailSection(info: .sfo, tintColor: .blue)
    }
}
