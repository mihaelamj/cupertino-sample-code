/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The weather grid view for a given flight leg that displays either hourly
 or daily weather forecasts.
*/

import CoreLocation.CLLocation
import SwiftUI
import WeatherKit

struct FlightLegDetailWeatherGrid: View {
    var flightInfo: FlightInfo
    var forecastInfo: [FlightForecastInfo]
    var headerColor: Color  = .primary
    var contentColor: Color = .gray
    
    var body: some View {
        Grid(alignment: .top) {
            HeaderGridRow(forecastInfo: forecastInfo, headerColor: headerColor)
            if forecastInfo.isEmpty {
                ForEach(0..<5) { _ in
                    GridRow {
                        Text("--")
                        Text("--")
                        Text("--")
                        Text("--")
                        Text("--")
                    }
                }
            } else {
                ForEach(forecastInfo, id: \.date) { forecast in
                    ForecastGridRow(forecast: forecast)
                }
            }
        }
        .foregroundColor(contentColor)
        .font(.callout)
    }
}

private struct HeaderGridRow: View {
    var forecastInfo: [FlightForecastInfo]
    var headerColor: Color
    
    var body: some View {
        GridRow {
            if forecastInfo.contains(where: { $0.isHourlyForecast }) {
                Text("Time")
                Text("Cond")
                Text("Temp")
                Text("Precip")
                Text("Wind")
            } else {
                Text("Date")
                Text("Cond")
                Text("Low")
                Text("High")
                Text("Precip")
            }
        }
        .foregroundColor(headerColor)
        .font(.headline)
        .fontWeight(.medium)
        .padding(.bottom, 6)
        .textCase(.uppercase)
    }
}

private struct ForecastGridRow: View {
    var forecast: FlightForecastInfo
    
    var body: some View {
        GridRow {
            if forecast.isHourlyForecast {
                Text(forecast.date, format: timeFormat)
            } else {
                Text(forecast.date, format: dateFormat)
            }
            Image(systemName: forecast.symbolName)
            if case let .hourly(temp) = forecast.temperature {
                Text(formattedTemperature(temp))
            } else if case let .daily(high, low) = forecast.temperature {
                Text(formattedTemperature(high))
                Text(formattedTemperature(low))
            }
            if forecast.isHourlyForecast {
                Text(forecast.precipitation)
                Text(formattedSpeed(forecast.windSpeed))
            } else {
                Text(formattedPrecipitation(forecast.precipitation,
                    chance: forecast.precipitationChance))
            }
        }
    }
    
    var dateFormat: Date.FormatStyle {
        Date.FormatStyle()
            .weekday(.abbreviated)
            .month(.defaultDigits)
            .day(.defaultDigits)
    }
    
    var timeFormat: Date.FormatStyle {
        Date.FormatStyle().hour(.defaultDigits(amPM: .abbreviated))
    }
    
    func formattedTemperature(_ temp: Measurement<UnitTemperature>) -> String {
        temp.formatted(.measurement(width: .abbreviated, usage: .weather))
    }
    
    func formattedSpeed(_ speed: Measurement<UnitSpeed>) -> String {
        speed.formatted(.measurement(width: .abbreviated, usage: .general))
    }
    
    func formattedPrecipitation(_ precip: String, chance: Double) -> String {
        guard chance > 0 else { return precip }
        let percentage = Int(chance * 100)
        return precip + " (\(percentage)%)"
    }
}

struct FlightLegDetailWeatherGrid_Previews: PreviewProvider {
    static var previews: some View {
        let flightInfo = FlightInfo(airport: .sfo)
        return Group {
            FlightLegDetailWeatherGrid(
                flightInfo: flightInfo,
                forecastInfo: [])
            FlightLegDetailWeatherGrid(
                flightInfo: flightInfo,
                forecastInfo: [.hourly])
            FlightLegDetailWeatherGrid(
                flightInfo: flightInfo,
                forecastInfo: [.daily])
        }
    }
}
