/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view to add events to the user's Calendar without prompting them for access.
*/

import SwiftUI

struct ContentView: View {
    @StateObject private var model: LessonModel = LessonModel(date: Date())
    
    var body: some View {
        DropInLessonPicker(model: model)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
