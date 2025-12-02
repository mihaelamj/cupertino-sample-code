/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A booking button.
*/

import SwiftUI

struct BookingButton: View {
    @Binding var selection: Lesson?
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            buildText(selection: selection)
        }
        .buttonStyle(.booking)
        .disabled(selection == nil)
        .scenePadding()
    }
    
    @ViewBuilder
    /// The text of the booking button based on the value of the lesson type.
    func buildText(selection: Lesson?) -> some View {
        if let selection = selection {
            switch selection.type {
                case .single: Text(selection.titleAndStartAt)
                case .recurring: Text(selection.titleAndBook)
            }
        } else {
            Text("Book lesson")
        }
    }
}

struct BookingButton_Previews: PreviewProvider {
    static var previews: some View {
        BookingButton(selection: .constant(Lesson.dropinLessonMock), action: {})
        BookingButton(selection: .constant(Lesson.repeatingLessonMock), action: {})
        BookingButton(selection: .constant(nil), action: {})
    }
}
