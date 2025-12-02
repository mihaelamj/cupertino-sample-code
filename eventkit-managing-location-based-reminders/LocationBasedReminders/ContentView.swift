/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view.
*/

import SwiftUI

struct ContentView: View {
    @State private var manager = ReminderStoreManager()
    
    var body: some View {
        WelcomeView()
            .task {
                await manager.listenForCalendarChanges()
            }
            .environment(manager)
    }
}

#Preview {
    ContentView()
        .environment(ReminderStoreManager())
}
