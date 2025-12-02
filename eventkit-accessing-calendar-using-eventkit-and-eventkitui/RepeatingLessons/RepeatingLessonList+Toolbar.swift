/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The toolbar for the repeating lesson list view.
*/

import SwiftUI

extension RepeatingLessonList {
    @ToolbarContentBuilder
    /*
        Displays a button  that launches the calendar chooser view controller when the user taps it. The app enables the button when the user granted
        write-only or full access to the app. It disables it, otherwise.
    */
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                showCalendarChooser.toggle()
            }) {
                Text("Select calendar")
            }
            .disabled(!storeManager.isWriteOnlyOrFullAccessAuthorized)
        }
    }
}
