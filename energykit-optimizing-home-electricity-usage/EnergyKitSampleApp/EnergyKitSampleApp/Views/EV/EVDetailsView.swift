/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The electric vehicle detailed view that displays a managed charging session.
*/

import Charts
import EnergyKit
import SwiftUI

struct EVDetailsView: View {
    @Environment(ElectricVehicleController.self) private var model
    @Environment(EnergyVenueManager.self) private var energyVenueManager

    @State var selectedTime: Date?
    @State private var selectedData: DataCategory = .chargingData

    var evForTime: ElectricVehicle? {
        if let selectedTime {
            if let value = model.snapshots.first(
                where: { selectedTime >= $0.state.timestamp && selectedTime < $0.state.timestamp.addingTimeInterval(60) }
            ) {
                return value
            }
        }
        return nil
    }

    var body: some View {
        let selectedValue = evForTime
        NavigationView {
            List {
                Picker("Data", selection: $selectedData) {
                        Text("Charging Data").tag(DataCategory.chargingData)
                        Text("Insights").tag(DataCategory.insightsData)
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedData) {
                    Task {
                        model.insights = (try? await energyVenueManager.generateInsights(
                            for: model.configuration.properties.vehicleID,
                            on: Date.now.addingTimeInterval(-30 * 24 * 60 * 60)
                        )) ?? []
                    }
                }

                // Display data based on the selection.
                if selectedData == .chargingData {
                    chargingDataSection(selectedValue)
                } else {
                    if !model.insights.isEmpty {
                        insightsDataSection(model.insights)
                    } else {
                        ContentUnavailableView {
                            Label("Insights unavailable", systemImage: "weekly.summary")
                        } description: {
                            Text("Insights are generated based on historical data and will appear here once available.")
                        }
                    }
                }

                Section(header: Text("Feedback").textCase(.uppercase)) {
                    NavigationLink(destination: LoadEventsView()) {
                        Text("Load Events")
                    }
                    .environment(model)
                }
            }
            .listStyle(.inset)
            .navigationTitle("EV Details")
            .onAppear {
                // Run the electric vehicle simulation.
                model.runSimulationWithGuidance()
            }
        }
    }

    /// Provides the electric vehicle description.
    var evDescription: some View {
        VStack {
            AttributeValueTextView(
                attribute: "Battery Capacity:",
                value: "\(model.configuration.properties.batteryCapacity) kWh"
            )
            AttributeValueTextView(
                attribute: "Charging Power:",
                value: "\(model.configuration.properties.chargingPower) kW"
            )
            AttributeValueTextView(
                attribute: "Desired State Of Charge",
                value: "\(model.configuration.properties.desiredStateOfCharge.formatted()) %"
            )
            AttributeValueTextView(
                attribute: "Timestep:",
                value: "\(model.timestep.formatted()) minutes"
            )
        }
    }

    func chargingDataSection(_ selectedValue: ElectricVehicle?) -> some View {
        return Section(header: Text("Charging Data").textCase(.uppercase)) {
            VStack {
                evDescription
                    .opacity(selectedValue == nil ? 1.0 : 0.0)

                Chart {
                    // Selection view.
                    if let selectedValue {
                        evAnnotationFor(value: selectedValue)
                    }

                    stateOfCharge()
                        .foregroundStyle(.green)
                }
                .chartXSelection(value: $selectedTime)
                .aspectRatio(contentMode: .fill)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                        AxisValueLabel(format: .dateTime.hour())
                        AxisGridLine()
                        AxisTick()
                    }
                }
            }
        }
    }
    func insightsDataSection(_ insights: [ElectricityInsightRecord<Measurement<UnitEnergy>>]) -> some View {
        let dateRange = insights.compactMap { $0.range.start }.sorted()
        let startDate = dateRange.first ?? Date()
        let endDate = dateRange.last ?? Date()
        
        return VStack(spacing: 16) {
            // Total Energy Over Time Chart
            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Energy Consumption")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(insights, id: \.range.start) { record in
                            if let totalEnergy = record.totalEnergy {
                                BarMark(
                                    x: .value("Date", record.range.start, unit: .day),
                                    y: .value("Energy", totalEnergy.converted(to: .kilowattHours).value)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            AxisValueLabel(format: .dateTime.month().day())
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                            AxisGridLine()
                            AxisTick()
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Cleanliness Breakdown Chart
                if insights.contains(where: { $0.dataByGridCleanliness != nil }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Energy by Grid Cleanliness")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(insights, id: \.range.start) { record in
                                if let cleanliness = record.dataByGridCleanliness {
                                    if let cleaner = cleanliness.cleaner {
                                        BarMark(
                                            x: .value("Date", record.range.start, unit: .day),
                                            y: .value("Energy", cleaner.converted(to: .kilowattHours).value)
                                        )
                                        .foregroundStyle(.green)
                                    }
                                    if let lessClean = cleanliness.lessClean {
                                        BarMark(
                                            x: .value("Date", record.range.start, unit: .day),
                                            y: .value("Energy", lessClean.converted(to: .kilowattHours).value)
                                        )
                                        .foregroundStyle(.yellow)
                                    }
                                    if let avoid = cleanliness.avoid {
                                        BarMark(
                                            x: .value("Date", record.range.start, unit: .day),
                                            y: .value("Energy", avoid.converted(to: .kilowattHours).value)
                                        )
                                        .foregroundStyle(.red)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                AxisValueLabel(format: .dateTime.month().day())
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                        .chartForegroundStyleScale([
                            "Cleaner": .green,
                            "LessClean": .yellow,
                            "Avoid": .red
                        ])
                        .padding(.horizontal)
                    }
                }
                
                // Tariff Breakdown Chart
                if insights.contains(where: { $0.dataByTariffPeak != nil }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Energy by Tariff Period")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(insights, id: \.range.start) { record in
                                if let tariff = record.dataByTariffPeak {
                                    if let offPeak = tariff.offPeak {
                                        BarMark(
                                            x: .value("Date", record.range.start, unit: .day),
                                            y: .value("Energy", offPeak.converted(to: .kilowattHours).value)
                                        )
                                        .foregroundStyle(.green)
                                    }
                                    if let partialPeak = tariff.partialPeak {
                                        BarMark(
                                            x: .value("Date", record.range.start, unit: .day),
                                            y: .value("Energy", partialPeak.converted(to: .kilowattHours).value)
                                        )
                                        .foregroundStyle(.orange)
                                    }
                                    if let onPeak = tariff.onPeak {
                                        BarMark(
                                            x: .value("Date", record.range.start, unit: .day),
                                            y: .value("Energy", onPeak.converted(to: .kilowattHours).value)
                                        )
                                        .foregroundStyle(.red)
                                    }
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                AxisValueLabel(format: .dateTime.month().day())
                                AxisGridLine()
                                AxisTick()
                            }
                        }
                        .chartForegroundStyleScale([
                            "Off-Peak": .green,
                            "Partial Peak": .orange,
                            "On-Peak": .red
                        ])
                        .padding(.horizontal)
                    }
                }
                
                // Summary Statistics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                        .padding(.horizontal)
                    let totalEnergySum = insights.compactMap { $0.totalEnergy }.reduce(
                        Measurement(value: 0, unit: UnitEnergy.kilowattHours)) { $0 + $1 }
                    let averageDaily = totalEnergySum.value / Double(max(insights.count, 1))
                    
                    VStack(spacing: 4) {
                        AttributeValueTextView(
                            attribute: "Total Energy:",
                            value: String(format: "%.2f kWh", totalEnergySum.value)
                        )
                        AttributeValueTextView(
                            attribute: "Average Daily:",
                            value: String(format: "%.2f kWh", averageDaily)
                        )
                        AttributeValueTextView(
                            attribute: "Days with Data:",
                            value: "\(insights.count) of 31"
                        )
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
    }

    /// Provides the state of the charge line plot.
    @ChartContentBuilder
    func stateOfCharge() -> some ChartContent {
        LinePlot(
            model.snapshots,
            x: .value("Time", \.state.timestamp),
            y: .value("StateOfCharge", \.state.stateOfCharge)
        )
        .foregroundStyle(.green)
    }

    /// Provides the electric vehicle annotation for the selected value.
    @ChartContentBuilder
    func evAnnotationFor(value: ElectricVehicle) -> some ChartContent {
        RuleMark(x: .value("selected time", selectedTime!, unit: .minute))
            .foregroundStyle(Color.gray.opacity(0.3))
            .offset(yStart: -11)
            .annotation(
                position: .top,
                spacing: 0,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                batteryInfo(for: value)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(Color.gray.opacity(0.3))
                }
            }
    }

    // MARK: The views presented as annotations for the selected value
    func batteryInfo(for value: ElectricVehicle) -> some View {
        VStack(alignment: .leading) {
            Text("State Of Charge").font(.subheadline)
            Text("\(value.state.stateOfCharge, specifier: "%.2f") %")
                .font(.title).bold()

            HStack(spacing: 0) {
                Text(value.state.timestamp.formatted(.dateTime.month().day()))

                selectedTime.map {
                    Text(", \($0.formatted(.dateTime.hour().minute()))")
                } ?? Text("")
            }
            .font(.subheadline)
            .bold()
        }
    }

    private enum  DataCategory: Int {
        case chargingData
        case insightsData
    }
}
