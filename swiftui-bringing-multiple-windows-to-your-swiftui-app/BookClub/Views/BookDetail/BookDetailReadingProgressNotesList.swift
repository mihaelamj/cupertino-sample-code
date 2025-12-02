/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book detail subview displaying the user's reading progress notes in a list.
*/

import SwiftUI

struct BookDetailReadingProgressNotesList: View {
    private var entriesByDate: [ReadingProgress.EntriesByDate]
    
    init(progress: ReadingProgress) {
        entriesByDate = progress.entriesByDate.reversed()
    }
    
    var body: some View {
        if entriesByDate.isEmpty {
            Text("--")
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(minHeight: 50)
        } else {
            VStack(alignment: .leading) {
                ForEach(entriesByDate, id: \.self) { value in
                    Section {
                        ForEach(value.entries.sorted(by: >)) { entry in
                            BookDetailReadingProgressRow(entry: entry)
                        }
                    } header: {
                        VStack(alignment: .leading) {
                            Text(value.date, style: .date)
                                .font(.subheadline)
                                .padding(padding)
                            Divider()
                        }
                    }
                }
            }
            .frame(minHeight: 100)
        }
    }
    
    var padding: EdgeInsets {
        EdgeInsets(top: 8, leading: 12, bottom: 0, trailing: 12)
    }
}

struct BookDetailReadingProgressNotesList_Previews: PreviewProvider {
    static var previews: some View {
        let progress = CurrentlyReading.mock.progress
        return BookDetailReadingProgressNotesList(progress: progress)
    }
}
