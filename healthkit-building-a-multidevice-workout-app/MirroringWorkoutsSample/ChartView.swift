/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout charts.
*/

import HealthKit
import SwiftUI
import Charts

struct LineChartEntry: Identifiable, Hashable {
    let category: String
    let date: Date
    let value: Double
    var id: Date {
        date
    }
}

struct ChartView: View {
    @Binding var workout: HKWorkout?
    @State private var speedEntries = [LineChartEntry]()
    @State private var powerEntries = [LineChartEntry]()
    @State private var cadenceEntries = [LineChartEntry]()

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Spacer(minLength: 15)
                    GroupBox("Speed") {
                        Chart(speedEntries) { entry in
                            LineMark(
                                x: .value("Time", entry.date, unit: .minute),
                                y: .value("Speed", entry.value)
                            )
                            .symbol(by: .value("Speed", entry.category))
                            .interpolationMethod(.catmullRom)
                        }
                        .chartLegend(.hidden)
                    }
                    Spacer(minLength: 15)
                }
                HStack {
                    Spacer(minLength: 15)
                    GroupBox("Power") {
                        Chart(powerEntries) { entry in
                            LineMark(
                                x: .value("Time", entry.date, unit: .minute),
                                y: .value("Power", entry.value)
                            )
                        }
                        .chartLegend(.hidden)
                    }
                    Spacer(minLength: 15)
                }
                HStack {
                    Spacer(minLength: 15)

                    GroupBox("Cadence") {
                        Chart(cadenceEntries) { entry in
                            LineMark(
                                x: .value("Time", entry.date, unit: .minute),
                                y: .value("Cadence", entry.value)
                            )
                        }
                        .chartLegend(.hidden)
                    }
                    Spacer(minLength: 15)

                }
                
                HStack {
                    Spacer(minLength: 15)
                    GroupBox("Summary") {
                        SummaryView(workout: $workout)
                    }
                    Spacer(minLength: 15)
                }
            }
            .task(id: workout) {
                /**
                 HKWorkout is an NSObject, which complies with Equatable, and the default implementation is comparing the object pointer,
                 which is exactly what this case needs.
                 SwiftUI cancels and recreates the task when the selected workout changes, so the UI always displays the latest selection.
                 */
                await updateLineEntries()
            }
        }
    }
    
    private func updateLineEntries() async {
        guard let workout = workout else {
            speedEntries = []
            powerEntries = []
            cadenceEntries = []
            return
        }
        let workoutManager = WorkoutManager.shared
        /**
         Fetching cycling speed statistics.
         */
        let speedStatisticsList = await workoutManager.fetchQuantityCollection(
            for: workout,
            quantityTypeIdentifier: .cyclingSpeed,
            statisticsOptions: .discreteAverage
        )
        speedEntries = speedStatisticsList.compactMap {
            if let speedValue = $0.averageQuantity()?.doubleValue(for: HKUnit.mile().unitDivided(by: HKUnit.hour())) {
                return LineChartEntry(category: "Speed", date: $0.endDate, value: speedValue)
            } else {
                return nil
            }
        }
        /**
         Fetching cycling power statistics.
         */
        let powerStatisticsList = await workoutManager.fetchQuantityCollection(
            for: workout,
            quantityTypeIdentifier: .cyclingPower,
            statisticsOptions: .discreteAverage
        )
        powerEntries = powerStatisticsList.compactMap {
            if let watt = $0.averageQuantity()?.doubleValue(for: .watt()) {
                return LineChartEntry(category: "Power", date: $0.endDate, value: watt)
            } else {
                return nil
            }
        }
        /**
         Fetching cycling cadence statistics.
         */
        let cadenceStatisticsList = await workoutManager.fetchQuantityCollection(
            for: workout,
            quantityTypeIdentifier: .cyclingCadence,
            statisticsOptions: .discreteAverage
        )
        cadenceEntries = cadenceStatisticsList.compactMap {
            let cadenceUnit = HKUnit.count().unitDivided(by: .minute())
            if let rpm = $0.averageQuantity()?.doubleValue(for: cadenceUnit) {
                return LineChartEntry(category: "Cadence", date: $0.endDate, value: rpm)
            } else {
                return nil
            }
        }
    }
}
