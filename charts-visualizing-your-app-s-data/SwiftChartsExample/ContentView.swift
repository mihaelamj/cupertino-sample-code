/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view of the app.
*/

import SwiftUI

struct ContentView: View {
    @State private var selection = 2

    var body: some View {
        #if os(macOS)
        SalesTab()
        #else
        TabView(selection: $selection) {
            MenuTab()
                .tabItem {
                    Label("Menu", systemImage: "fork.knife")
                }
                .tag(1)

            SalesTab()
                .tabItem {
                    Label("Sales", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(2)
        }
        #endif
    }
}

struct MenuTab: View {
    var body: some View {
        VStack {
            Image(systemName: "fork.knife.circle.fill")
                .font(.largeTitle)
            Text("Menu")
                .font(.title2.bold())
        }
        .foregroundStyle(.secondary)
    }
}

struct SalesTab: View {
    private enum Destinations {
        case empty
        case sales
        case styles
        case locations
        case salesMinMaxAverage
        case background
    }

    @State private var selection: Destinations?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    NavigationLink(value: Destinations.sales) {
                        SalesOverview()
                    }
                }
                Section {
                    NavigationLink(value: Destinations.styles) {
                        StylesOverview()
                    }
                }
                Section {
                    NavigationLink(value: Destinations.locations) {
                        LocationsOverview()
                    }
                }

                Section("Additional examples") {
                    NavigationLink("Daily Average, Min, Max", value: Destinations.salesMinMaxAverage)
                    NavigationLink("Plot Area Styling", value: Destinations.background)
                }
            }
            .navigationTitle("Sales")
            #if !os(macOS)
            .listStyle(.insetGrouped)
            #endif
        } detail: {
            NavigationStack {
                switch selection ?? .empty {
                case .empty: Text("Select data to view.")
                case .sales: SalesDetails()
                case .styles: StylesDetails()
                case .locations: LocationsDetails()
                case .salesMinMaxAverage: SalesMinMaxAverage()
                case .background: ChartWithBackground()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
