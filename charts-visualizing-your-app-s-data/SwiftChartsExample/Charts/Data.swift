/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Sample data.
*/

import SwiftUI
import GameplayKit

private let gaussianRandoms = GKGaussianDistribution(lowestValue: 0, highestValue: 20)

func date(year: Int, month: Int, day: Int = 1) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
}

/// Data for the top style charts.
struct TopStyleData {
    /// Sales by pancake style for the last 30 days, sorted by amount.
    static let last30Days = [
        (name: "Cachapa", sales: 916),
        (name: "Injera", sales: 820),
        (name: "Crêpe", sales: 610),
        (name: "Jian Bing", sales: 350),
        (name: "Dosa", sales: 144),
        (name: "American", sales: 66)
    ]

    /// Sales by pancake style for the last 12 months, sorted by amount.
    static let last12Months = [
        (name: "Cachapa", sales: 9631),
        (name: "Crêpe", sales: 6200),
        (name: "Injera", sales: 7891),
        (name: "Jian Bing", sales: 3300),
        (name: "American", sales: 700),
        (name: "Dosa", sales: 1400)
    ]
}

/// Data for the daily and monthly sales charts.
struct SalesData {
    /// Sales by day for the last 30 days.
    static let last30Days = [
        (day: date(year: 2022, month: 5, day: 8), sales: 168),
        (day: date(year: 2022, month: 5, day: 9), sales: 117),
        (day: date(year: 2022, month: 5, day: 10), sales: 106),
        (day: date(year: 2022, month: 5, day: 11), sales: 119),
        (day: date(year: 2022, month: 5, day: 12), sales: 109),
        (day: date(year: 2022, month: 5, day: 13), sales: 104),
        (day: date(year: 2022, month: 5, day: 14), sales: 196),
        (day: date(year: 2022, month: 5, day: 15), sales: 172),
        (day: date(year: 2022, month: 5, day: 16), sales: 122),
        (day: date(year: 2022, month: 5, day: 17), sales: 115),
        (day: date(year: 2022, month: 5, day: 18), sales: 138),
        (day: date(year: 2022, month: 5, day: 19), sales: 110),
        (day: date(year: 2022, month: 5, day: 20), sales: 106),
        (day: date(year: 2022, month: 5, day: 21), sales: 187),
        (day: date(year: 2022, month: 5, day: 22), sales: 187),
        (day: date(year: 2022, month: 5, day: 23), sales: 119),
        (day: date(year: 2022, month: 5, day: 24), sales: 160),
        (day: date(year: 2022, month: 5, day: 25), sales: 144),
        (day: date(year: 2022, month: 5, day: 26), sales: 152),
        (day: date(year: 2022, month: 5, day: 27), sales: 148),
        (day: date(year: 2022, month: 5, day: 28), sales: 240),
        (day: date(year: 2022, month: 5, day: 29), sales: 242),
        (day: date(year: 2022, month: 5, day: 30), sales: 173),
        (day: date(year: 2022, month: 5, day: 31), sales: 143),
        (day: date(year: 2022, month: 6, day: 1), sales: 137),
        (day: date(year: 2022, month: 6, day: 2), sales: 123),
        (day: date(year: 2022, month: 6, day: 3), sales: 146),
        (day: date(year: 2022, month: 6, day: 4), sales: 214),
        (day: date(year: 2022, month: 6, day: 5), sales: 250),
        (day: date(year: 2022, month: 6, day: 6), sales: 146)
    ]

    /// Total sales for the last 30 days.
    static var last30DaysTotal: Int {
        last30Days.map { $0.sales }.reduce(0, +)
    }

    static var last30DaysAverage: Double {
        Double(last30DaysTotal / last30Days.count)
    }

    private static func randomSalesForDay(_ dayNumber: Double) -> Int {
        // Add noise to the generated data.
        let yearlySeasonality = 100.0 * (0.5 - 0.5 * cos(2.0 * .pi * (dayNumber / 364.0)))
        let monthlySeasonality = 10.0 * (0.5 - 0.5 * cos(2.0 * .pi * (dayNumber / 30.0)))
        let weeklySeasonality = 30.0 * (1 - cos(2.0 * .pi * ((dayNumber + 2.0) / 7.0)))
        return Int(yearlySeasonality + monthlySeasonality + weeklySeasonality + Double(gaussianRandoms.nextInt()))
    }

    /// Sales by day for the last 365 days.
    static let last365Days: [(day: Date, sales: Int)] = stride(from: 0, to: 200, by: 1).compactMap {
        let startDay: Date = date(year: 2022, month: 11, day: 17)  // 200 days before WWDC
        let day: Date = Calendar.current.date(byAdding: .day, value: $0, to: startDay)!
        let dayNumber = Double($0)
        
        var sales = randomSalesForDay(dayNumber)
        let dayOfWeek = Calendar.current.component(.weekday, from: day)
        if dayOfWeek == 6 {
            sales += gaussianRandoms.nextInt() * 3
        } else if dayOfWeek == 7 {
            sales += gaussianRandoms.nextInt()
        } else {
            sales = Int(Double(sales) * Double.random(in: 4...5) / Double.random(in: 5...6))
        }
        return (
            day: day,
            sales: sales
        )
    }
    
    static func salesInPeriod(in range: ClosedRange<Date>) -> Int {
        SalesData.last365Days.filter { range.contains($0.day) }.reduce(0) { $0 + $1.sales }
    }
    
    /// Total sales for the last 365 days.
    static var last365DaysTotal: Int {
        last365Days.map { $0.sales }.reduce(0, +)
    }

    static var last365DaysAverage: Double {
        Double(last365DaysTotal / last365DaysTotal)
    }

    /// Sales by month for the last 12 months.
    static let last12Months = [
        (month: date(year: 2021, month: 7), sales: 3952, dailyAverage: 127, dailyMin: 95, dailyMax: 194),
        (month: date(year: 2021, month: 8), sales: 4044, dailyAverage: 130, dailyMin: 96, dailyMax: 189),
        (month: date(year: 2021, month: 9), sales: 3930, dailyAverage: 131, dailyMin: 101, dailyMax: 184),
        (month: date(year: 2021, month: 10), sales: 4217, dailyAverage: 136, dailyMin: 96, dailyMax: 193),
        (month: date(year: 2021, month: 11), sales: 4006, dailyAverage: 134, dailyMin: 104, dailyMax: 202),
        (month: date(year: 2021, month: 12), sales: 3994, dailyAverage: 129, dailyMin: 96, dailyMax: 190),
        (month: date(year: 2022, month: 1), sales: 4202, dailyAverage: 136, dailyMin: 96, dailyMax: 203),
        (month: date(year: 2022, month: 2), sales: 3749, dailyAverage: 134, dailyMin: 98, dailyMax: 200),
        (month: date(year: 2022, month: 3), sales: 4329, dailyAverage: 140, dailyMin: 104, dailyMax: 218),
        (month: date(year: 2022, month: 4), sales: 4084, dailyAverage: 136, dailyMin: 93, dailyMax: 221),
        (month: date(year: 2022, month: 5), sales: 4559, dailyAverage: 147, dailyMin: 104, dailyMax: 242),
        (month: date(year: 2022, month: 6), sales: 1023, dailyAverage: 170, dailyMin: 120, dailyMax: 250)
    ]

    /// Total sales for the last 12 months.
    static var last12MonthsTotal: Int {
        last12Months.map { $0.sales }.reduce(0, +)
    }

    static var last12MonthsDailyAverage: Int {
        last12Months.map { $0.dailyAverage }.reduce(0, +) / last12Months.count
    }
}

/// Data for the sales by location and weekday charts.
struct LocationData {
    /// A data series for the lines.
    struct Series: Identifiable {
        /// The name of the city.
        let city: String

        /// Average daily sales for each weekday.
        /// The `weekday` property is a `Date` that represents a weekday.
        let sales: [(day: Date, sales: Int)]

        /// The identifier for the series.
        var id: String { city }
    }

    /// Sales by location and weekday for the last 30 days.
    static let last30Days: [Series] = [
        .init(city: "Cupertino", sales: [
            (day: date(year: 2022, month: 5, day: 2), sales: 54),
            (day: date(year: 2022, month: 5, day: 3), sales: 42),
            (day: date(year: 2022, month: 5, day: 4), sales: 88),
            (day: date(year: 2022, month: 5, day: 5), sales: 49),
            (day: date(year: 2022, month: 5, day: 6), sales: 42),
            (day: date(year: 2022, month: 5, day: 7), sales: 125),
            (day: date(year: 2022, month: 5, day: 8), sales: 67)

        ]),
        .init(city: "San Francisco", sales: [
            (day: date(year: 2022, month: 5, day: 2), sales: 81),
            (day: date(year: 2022, month: 5, day: 3), sales: 90),
            (day: date(year: 2022, month: 5, day: 4), sales: 52),
            (day: date(year: 2022, month: 5, day: 5), sales: 72),
            (day: date(year: 2022, month: 5, day: 6), sales: 84),
            (day: date(year: 2022, month: 5, day: 7), sales: 84),
            (day: date(year: 2022, month: 5, day: 8), sales: 137)
        ])
    ]

    /// The best weekday and location for the last 30 days.
    static let last30DaysBest = (
        city: "San Francisco",
        weekday: date(year: 2022, month: 5, day: 8),
        sales: 137
    )

    /// The best weekday and location for the last 12 months.
    static let last12MonthsBest = (
        city: "San Francisco",
        weekday: date(year: 2022, month: 5, day: 8),
        sales: 113
    )

    /// Sales by location and weekday for the last 12 months.
    static let last12Months: [Series] = [
        .init(city: "Cupertino", sales: [
            (day: date(year: 2022, month: 5, day: 2), sales: 64),
            (day: date(year: 2022, month: 5, day: 3), sales: 60),
            (day: date(year: 2022, month: 5, day: 4), sales: 47),
            (day: date(year: 2022, month: 5, day: 5), sales: 55),
            (day: date(year: 2022, month: 5, day: 6), sales: 55),
            (day: date(year: 2022, month: 5, day: 7), sales: 105),
            (day: date(year: 2022, month: 5, day: 8), sales: 67)
        ]),
        .init(city: "San Francisco", sales: [
            (day: date(year: 2022, month: 5, day: 2), sales: 57),
            (day: date(year: 2022, month: 5, day: 3), sales: 56),
            (day: date(year: 2022, month: 5, day: 4), sales: 66),
            (day: date(year: 2022, month: 5, day: 5), sales: 61),
            (day: date(year: 2022, month: 5, day: 6), sales: 60),
            (day: date(year: 2022, month: 5, day: 7), sales: 77),
            (day: date(year: 2022, month: 5, day: 8), sales: 113)
        ])
    ]
}
