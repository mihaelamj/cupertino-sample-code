/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book detail subview displaying the user's reading progress for a given entry.
*/

import SwiftUI

struct BookDetailReadingProgressRow: View {
    var entry: ReadingProgress.Entry
    
    var body: some View {
        HStack {
            CircularProgressView(value: entry.progress)
                .frame(width: 64, height: 64)
                .padding(.trailing)
            if let note = entry.note {
                Text(note)
                Spacer()
            }
        }
        .padding(padding)
    }
    
    var padding: EdgeInsets {
        EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12)
    }
}

struct BookDetailReadingProgressRow_Previews: PreviewProvider {
    static var previews: some View {
        let entry = CurrentlyReading.mock.progress.entries[0]
        return BookDetailReadingProgressRow(entry: entry)
    }
}
