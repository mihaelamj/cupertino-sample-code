/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Static weather for the default day.
*/

import Foundation

extension MockData {
    // MARK: Weather data

    // This example example weather data from 49º to 85º to highlight
    // the color gradient in the slider.
    // A real-world application would integrate with WeatherKit:
    // https://developer.apple.com/weatherkit/
    static let weather: [Weather] = [
        Weather(temperature: 56), // Temperature at midnight.
        Weather(temperature: 54),
        Weather(temperature: 52),
        Weather(temperature: 51),
        Weather(temperature: 50),
        Weather(temperature: 49), // The low temperature at sunrise.
        Weather(temperature: 51),
        Weather(temperature: 58),
        Weather(temperature: 68),
        Weather(temperature: 73),
        Weather(temperature: 77),
        Weather(temperature: 81),
        Weather(temperature: 84),
        Weather(temperature: 85),
        Weather(temperature: 85), // The high temperature at 2 p.m.
        Weather(temperature: 84),
        Weather(temperature: 83),
        Weather(temperature: 81),
        Weather(temperature: 78),
        Weather(temperature: 76),
        Weather(temperature: 72), // Temperature at sunset, 8 p.m.
        Weather(temperature: 68),
        Weather(temperature: 62),
        Weather(temperature: 58)
    ]

    static let sunriseTime = "5:12AM"
    static let sunsetTime = "7:45PM"
}
