/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tab view containing each screen of the app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FountainMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            ReverseGeocodeView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Reverse Geocode")
                }
            GeocodeView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Geocode")
                }
        }
    }
}

#Preview {
    ContentView()
}
