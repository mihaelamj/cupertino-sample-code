/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book detail subview displaying the user's reading history, including
 reading progress and entry notes.
*/

import SwiftUI

struct BookDetailReadingHistory: View {
    var progress: ReadingProgress
    
    var body: some View {
        VStack {
            Text("Reading Progress")
                .fontWeight(.medium)
                .padding(.vertical)
            BookDetailReadingProgressChart(entries: progress.entries)
            Divider()
                .padding(.vertical)
            Text("Notes")
                .fontWeight(.medium)
                .padding(.vertical)
            BookDetailReadingProgressNotesList(progress: progress)
        }
    }
}

struct BookDetailReadingHistory_Previews: PreviewProvider {
    static var previews: some View {
        BookDetailReadingHistory(progress: CurrentlyReading.mock.progress)
    }
}
