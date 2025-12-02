/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level view that creates all the examples for the app.
*/

import SwiftUI
import TipKit

struct ContentView: View {
    // Define an app state for showing tips.
    @Parameter
    static var isLoggedIn: Bool = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Inline tip view") {
                    InlineView()
                }

                NavigationLink("Popover tip view") {
                    PopoverView()
                }

                NavigationLink("Tip actions") {
                    ActionsView()
                }

                NavigationLink("Parameter rules") {
                    ParameterView()
                }

                NavigationLink("Event rules") {
                    EventView()
                }

                NavigationLink("Tip options") {
                    OptionView()
                }

                NavigationLink("Combined rules") {
                    ComboView()
                }
            }
            .navigationTitle("TipKit Examples")
        }
    }
}

#Preview {
    ContentView()
}
