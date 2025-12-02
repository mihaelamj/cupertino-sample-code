/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view to demonstrate Calendar full access.
*/

import SwiftUI

struct ContentView: View {
    @StateObject private var storeManager: EventStoreManager = EventStoreManager()
    
    var body: some View {
        WelcomeView()
            .environmentObject(storeManager)
            .task {
                await storeManager.listenForCalendarChanges()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(EventStoreManager())
    }
}
