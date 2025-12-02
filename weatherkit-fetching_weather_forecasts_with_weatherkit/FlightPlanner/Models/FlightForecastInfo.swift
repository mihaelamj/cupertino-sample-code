/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model that represents the primary components of a weather forecast for
 a flight leg.
*/

import Foundation
import WeatherKit

struct FlightForecastInfo {
    var date: Date
    var condition: String
    var symbolName: String
    var temperature: Temperature
    var precipitation: String
    var precipitationChance: Double
    var windSpeed: Measurement<UnitSpeed>
    
    var isDailyForecast: Bool {
        temperature.isDaily
    }
    
    var isHourlyForecast: Bool {
        !temperature.isDaily
    }
}

extension FlightForecastInfo {
    init(_ forecast: DayWeather) {
        date = forecast.date
        condition = forecast.condition.description
        symbolName = forecast.symbolName
        temperature = .daily(
            high: forecast.highTemperature,
            low: forecast.lowTemperature)
        precipitation = forecast.precipitation.description
        precipitationChance = forecast.precipitationChance
        windSpeed = forecast.wind.speed
    }
    
    init(_ forecast: HourWeather) {
        date = forecast.date
        condition = forecast.condition.description
        symbolName = forecast.symbolName
        temperature = .hourly(forecast.temperature)
        precipitation = forecast.precipitation.description
        precipitationChance = forecast.precipitationChance
        windSpeed = forecast.wind.speed
    }
}

extension FlightForecastInfo {
    enum Temperature {
        typealias Value = Measurement<UnitTemperature>
        
        case daily(high: Value, low: Value)
        case hourly(Value)
        
        var isDaily: Bool {
            switch self {
            case .daily:
                return true
            case .hourly:
                return false
            }
        }
    }
}

extension FlightForecastInfo.Temperature: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case let .daily(high, low):
            hasher.combine(0)
            hasher.combine(high)
            hasher.combine(low)
        case let .hourly(temp):
            hasher.combine(1)
            hasher.combine(temp)
        }
    }
}

#if DEBUG
// Use this for preview data.
extension FlightForecastInfo {
    static var daily: FlightForecastInfo {
        FlightForecastInfo(
            date: .now,
            condition: condition,
            symbolName: "cloud.sun.rain",
            temperature: dailyTemperature,
            precipitation: "rain",
            precipitationChance: 0.15,
            windSpeed: windSpeed)
    }
    
    static var hourly: FlightForecastInfo {
        FlightForecastInfo(
            date: .now,
            condition: condition,
            symbolName: "cloud.sun.rain",
            temperature: hourlyTemperature,
            precipitation: "rain",
            precipitationChance: 0.15,
            windSpeed: windSpeed)
    }
    
    private static let condition =
    """
    Lorem ipsum dolor sit amet, \
    consectetur adipiscing elit."
    """
    
    private static var hourlyTemperature: FlightForecastInfo.Temperature = {
        let temp = Measurement<UnitTemperature>(value: 60.1, unit: .fahrenheit)
        return .hourly(temp)
    }()

    private static var dailyTemperature: FlightForecastInfo.Temperature = {
        let high = Measurement<UnitTemperature>(value: 81.7, unit: .fahrenheit)
        let low = Measurement<UnitTemperature>(value: 52.4, unit: .fahrenheit)
        return .daily(high: high, low: low)
    }()

    private static var windSpeed: Measurement<UnitSpeed> = {
        Measurement<UnitSpeed>(value: 4.2, unit: .milesPerHour)
    }()
}
#endif
