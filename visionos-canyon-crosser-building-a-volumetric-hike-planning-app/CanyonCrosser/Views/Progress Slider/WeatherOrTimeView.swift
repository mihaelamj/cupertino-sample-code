/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A label that conditionally shows the weather or time for the timeline.
*/

import SwiftUI

struct WeatherOrTimeView: View {
    enum Display {
        case weather
        case time
    }

    let display: Display
    let weather: [Weather]
    let times: [Date]

    struct WeatherAndTime: Identifiable, Hashable {
        var id: Double { time.timeIntervalSinceReferenceDate }
        let weather: Weather
        let time: Date
    }

    var weatherAndTime: [WeatherAndTime] {
        Array(zip(weather, times)).map { WeatherAndTime(weather: $0, time: $1) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weatherAndTime, id: \.self) { item in
                ZStack {
                    switch display {
                    case .weather:
                        TimeLabel(time: item.time).hidden()
                        WeatherLabel(weather: item.weather)
                    case .time:
                        TimeLabel(time: item.time)
                        WeatherLabel(weather: item.weather).hidden()
                    }
                }

                if item != weatherAndTime.last! {
                    Spacer(minLength: 10)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    struct TimeLabel: View {
        let time: Date

        var body: some View {
            Text(time, format: .dateTime.hour())
                .textCase(.lowercase)
                .font(.caption.lowercaseSmallCaps())
                .foregroundStyle(.secondary)
        }
    }

    struct WeatherLabel: View {
        var weather: Weather

        var body: some View {
            Text("\(weather.temperature)º")
                .font(.callout.lowercaseSmallCaps())
        }
    }
}
