/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view.
*/

import SwiftUI

struct ContentView: View {
    @State private var preferredColumn: NavigationSplitViewColumn = .detail
    @State private var selectedScreen: AppScreen = .languages
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List {
                ForEach(AppScreen.allCases) { screen in
                    NavigationLink(value: screen) {
                        screen.label
                    }
                }
            }
            .navigationTitle(Text("भाषा ज्ञानी", comment: "Language Introspector"))
            .navigationDestination(for: AppScreen.self) { screen in
                NavigationStack {
                    screen.destination
                        .frame(maxWidth: 700)
                }
            }
            
        } detail: {
            NavigationStack {
                selectedScreen.destination
                    .frame(maxWidth: 700)
                    
            }
        }
    }
}

#Preview {
    ContentView()
}
