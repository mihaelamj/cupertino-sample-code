/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for showcasing medication dose samples for medications in a chart.
*/

import SwiftUI
import HealthKit
import Charts

struct MedicationChartsView: View {
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    private let medicationProvider = MedicationProvider()

    @State private var selectedMedication: AnnotatedMedicationConcept?
    @State private var dateConfiguration: DateConfiguration = DateConfiguration()
    @State private var doseEventProvider: DoseEventProvider = .init(healthStore: HealthStore.shared.healthStore,
                                                                    annotatedMedicationConcept: nil,
                                                                    dateInterval: .weeklyInterval)

    /// Maps the core model to a view model for the chart.
    var chartSeries: [ChartSeries] {
        return medicationProvider.activeMedicationConcepts.map { medicationConcept in
            ChartSeries(medicationConcept: medicationConcept,
                        samples: doseEventProvider.updatedDoseSampleCollection,
                        dateConfiguration: dateConfiguration)
        }
    }

    var body: some View {
        VStack {
            if medicationProvider.activeMedicationConcepts.isEmpty {
                Text("No Medication Authorized")
                    .bold()
            } else {
                MedicationSelectorView(concepts:
                                        medicationProvider.activeMedicationConcepts,
                                       selectedMedication: $selectedMedication)
            }

            if selectedMedication?.name == nil {
                Spacer()
                Text("No Medication Selected")
                    .bold()
            } else {
                ChartsView(dateConfiguration: $dateConfiguration,
                           chartSeries: chartSeries)
                .padding([.leading, .trailing])
            }
            Spacer()
        }
        .onChange(of: selectedMedication) { oldValue, newValue in
            doseEventProvider = .init(healthStore: HealthStore.shared.healthStore,
                                      annotatedMedicationConcept: selectedMedication,
                                      dateInterval: dateConfiguration.queryDateInterval)
        }
        .onAppear {
            Task {
                /// Fetch medication data each time.
                await medicationProvider.loadDataFromHealthKit()
            }
        }
    }

    // MARK: - Models

    /// A configuration of a particular lens into aggregating and visualizing data over a date interval.
    struct DateConfiguration: Equatable {
        /// The date representing the most-recent date currently displaying.
        var anchorDate: Date = Calendar.current.startOfDay(for: Date()) // Begin with midnight today as the anchor.
        /// The component to stride through when aggregating data.
        var aggregationCalendarComponent: Calendar.Component = .day
        /// The number of strides back in time from the anchor date.
        var aggregationBinCount: Int = 7

        /// The date interval working backward from the anchor date by the number of bins.
        var chartingDateInterval: DateInterval {
            .init(start: Calendar.current.date(byAdding: aggregationCalendarComponent,
                                               value: -(aggregationBinCount - 1), // Subtract 1 to avoid creating an additional bin.
                                               to: anchorDate)!,
                  end: anchorDate)
        }
        /// The date interval for querying backing data.
        var queryDateInterval: DateInterval {
            // Adjust the query date interval to be inclusive of today because the charting date interval normalizes to midnight today.
            .init(start: chartingDateInterval.start,
                  end: Calendar.current.date(byAdding: aggregationCalendarComponent, value: 1, to: anchorDate)!)
        }

        /// The bins to use to group data into chart points.
        var dateBins: DateBins { DateBins(unit: aggregationCalendarComponent,
                                          range: .init(uncheckedBounds: (chartingDateInterval.start, chartingDateInterval.end))) }

        /// Shifts the configuration back by one group of bins.
        mutating func decrement() {
            anchorDate = Calendar.current.date(byAdding: aggregationCalendarComponent,
                                               value: -aggregationBinCount,
                                               to: anchorDate)!
        }

        /// Shifts the configuration forward by one group of bins.
        mutating func increment() {
            anchorDate = Calendar.current.date(byAdding: aggregationCalendarComponent,
                                               value: aggregationBinCount,
                                               to: anchorDate)!
        }
    }
}
