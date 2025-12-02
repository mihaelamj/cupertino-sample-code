/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top level tab navigation for the app.
*/

import SwiftUI

struct ContentView: View {
    @Environment(DataModel.self) private var dataModel

    var body: some View {
        NavigationStack {
            Group {
                switch dataModel.displayMode {
                case .table:
                    ContactTable()
                case .list:
                    ContactList()
                }
            }
            .environment(dataModel)
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    @Bindable var dataModel = dataModel
                    DisplayModePicker(mode: $dataModel.displayMode)
                }
            }
        }
    }
}

#Preview() {
    ContentView()
        .environment(DataModel())
}

