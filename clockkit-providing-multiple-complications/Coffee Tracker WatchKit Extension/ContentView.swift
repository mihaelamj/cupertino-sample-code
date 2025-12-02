/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper view that instantiates the coffee tracker view and the data for the hosting controller.
*/

import SwiftUI
import os

// The ContentView wrapper simplifies adding the main view to the hosting controller.
struct ContentView: View {
    
    let logger = Logger(subsystem: "com.example.apple-samplecode.Coffee-Tracker.watchkitapp.watchkitextension.ContengView", category: "Root View")
        
    // Access the shared model object.
    let data = CoffeeData.shared
    
    // Create the main view, and pass the model.
    var body: some View {
        CoffeeTrackerView()
            .environmentObject(data)
    }
}

// A SwiftUI preview that displays the ContentView.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
