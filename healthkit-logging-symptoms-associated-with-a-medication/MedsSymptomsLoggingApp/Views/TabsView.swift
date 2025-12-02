/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that manages the top-level tabs of the app.
*/

import SwiftUI
import HealthKit

/// The top-level tab view for the app.
struct TabsView: View {
    /// The types of tabs for the app.
    enum TabKind: Hashable {
        case today
        case charts
    }

    /// The tab to select on appear, if any.
    private var initialTabKind: TabKind? = nil

    @Binding var toggleHealthDataAuthorization: Bool
    @Binding var healthDataAuthorized: Bool?

    var healthStore: HKHealthStore { HealthStore.shared.healthStore }
    @State private var selectedTabKind: TabKind = .today

    init(toggleHealthDataAuthorization: Binding<Bool>,
         healthDataAuthorized: Binding<Bool?>) {
        self._toggleHealthDataAuthorization = toggleHealthDataAuthorization
        self._healthDataAuthorized = healthDataAuthorized
    }

    var body: some View {
        TabView(selection: $selectedTabKind) {
            Tab(.todayViewDisplayTitle, systemImage: "calendar.day.timeline.leading", value: TabKind.today) {
                todayView()
            }
            Tab(.chartsViewDisplayTitle, systemImage: "chart.bar.xaxis", value: TabKind.charts) {
                calendarChartsView()
            }
        }
        .onAppear {
            if let initialTabKind {
                selectedTabKind = initialTabKind
            }
        }
    }

    @ViewBuilder
    private func todayView() -> some View {
        NavigationStack {
            HealthKitAuthorizationGatedView(authorized: $healthDataAuthorized) {
                MedicationListView()
                    .navigationTitle(.todayViewDisplayTitle)
            }
        }
    }

    @ViewBuilder
    private func calendarChartsView() -> some View {
        NavigationStack {
            HealthKitAuthorizationGatedView(authorized: $healthDataAuthorized) {
                MedicationChartsView()
                    .navigationTitle(.chartsViewDisplayTitle)
            }
        }
    }
}

@MainActor
extension LocalizedStringKey {
    static let todayViewDisplayTitle: LocalizedStringKey = "Today"
    static let chartsViewDisplayTitle: LocalizedStringKey = "Charts"
}
