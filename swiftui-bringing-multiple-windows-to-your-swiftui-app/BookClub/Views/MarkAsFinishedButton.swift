/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button to mark a book as finished, which sets its reading progress to 100%.
*/

import SwiftUI

struct MarkAsFinishedButton: View {
    @ObservedObject var currentlyReading: CurrentlyReading
    
    init(book currentlyReading: CurrentlyReading) {
        self.currentlyReading = currentlyReading
    }
    
    var body: some View {
        Button {
            withAnimation {
                currentlyReading.isFinished.toggle()
            }
        } label: {
            Label("Mark As Finished", systemImage: "checkmark.square")
        }
        .help("Mark the book's reading progress as completed.")
        .disabled(currentlyReading.isFinished)
    }
}

struct MarkAsFinishedButton_Previews: PreviewProvider {
    static var previews: some View {
        MarkAsFinishedButton(book: .mock)
    }
}
