/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view to demonstrate Calendar write-only access.
*/

import SwiftUI

struct ContentView: View {
    @StateObject private var model: LessonModel = LessonModel(date: Date())
    @StateObject private var storeManager: EventStoreManager = EventStoreManager()
    
    var body: some View {
        RepeatingLessonList(model: model)
            .environmentObject(EventStoreManager())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
