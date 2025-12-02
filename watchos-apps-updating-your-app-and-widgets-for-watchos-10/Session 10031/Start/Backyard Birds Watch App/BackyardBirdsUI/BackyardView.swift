/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of a backyard.
*/

import SwiftUI

struct BackyardView: View {
    var backyard: Backyard

    @State var waterLevel = 30
    @State var foodLevel = 60
    
    @State var isShowingRefillView = false

    var body: some View {
        List {
            Section {
                TodayView()
            } header: {
                Text("Today")
            } footer: {
                Divider()
            }
            Section {
                HabitatView($isShowingRefillView,
                            $waterLevel,
                            $foodLevel)
                HabitatLevelButton($isShowingRefillView)
            } header: {
                Text("Habitat")
            } footer: {
                Divider()
            }
            Section("Visitors") {
                VisitorView()
            }
        }
        .background(.black)
        .environmentObject(backyard)
        .navigationTitle(backyard.displayName)
    }
}

struct BackyardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BackyardView(backyard: .preview)
        }
    }
}
