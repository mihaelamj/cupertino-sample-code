/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metric and controls as two pages.
*/

import SwiftUI

struct PagingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var selection: Tab = .metrics
    @State private var isSheetActive = false

    private enum Tab {
        case controls, metrics
    }

    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
            MetricsView().tag(Tab.metrics)
        }
        .navigationTitle("Cycling")
        .navigationBarBackButtonHidden(true)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic))
        .onChange(of: isLuminanceReduced) {
            displayMetricsView()
        }
        .onChange(of: workoutManager.sessionState) { _, newValue in
            if newValue == .ended {
                isSheetActive = true
            } else if newValue == .running || newValue == .paused {
                displayMetricsView()
            }
        }
        .onAppear {
            workoutManager.requestAuthorization()
            selection = .metrics
        }
        .sheet(isPresented: $isSheetActive) {
            workoutManager.resetWorkout()
        } content: {
            SummaryView()
        }
    }

    private func displayMetricsView() {
        //withAnimation {
            selection = .metrics
        //}
    }
}
