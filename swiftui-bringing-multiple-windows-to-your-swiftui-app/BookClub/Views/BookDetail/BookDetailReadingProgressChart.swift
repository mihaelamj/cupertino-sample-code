/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book detail subview displaying the user's reading progress as a line chart.
*/

import SwiftUI
import Charts

struct BookDetailReadingProgressChart: View {
    var entries: [ReadingProgress.Entry]
    
    var body: some View {
        if entries.isEmpty {
            Text("--")
                .foregroundColor(.secondary)
                .font(.caption)
                .frame(minHeight: 50)
        } else {
            Chart(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Progress", entry.progress)
                )
            }
            .frame(minHeight: 100)
        }
    }
}

struct BookDetailReadingProgressChart_Previews: PreviewProvider {
    static var previews: some View {
        let entries = CurrentlyReading.mock.progress.entries
        return BookDetailReadingProgressChart(entries: entries)
    }
}
