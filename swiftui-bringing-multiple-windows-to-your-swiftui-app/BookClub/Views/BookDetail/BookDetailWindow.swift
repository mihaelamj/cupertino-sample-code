/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book detail view, which opens in its own presented window, displaying the
 book metadata, current reading progress, and notes.
*/

import SwiftUI

struct BookDetailWindow: View {
    @ObservedObject var dataModel: ReadingListModel
    @Binding var bookId: Book.ID?

    var body: some View {
        if let bookId = bookId, let book = dataModel[book: bookId] {
            BookDetailContent(dataModel: dataModel, book: book)
        } else {
            Text("No Book Selected")
                .font(.title)
                .foregroundStyle(.tertiary)
        }
    }
}

struct BookDetailWindow_Previews: PreviewProvider {
    static var previews: some View {
        let dataModel = ReadingListModel()
        let bookId = CurrentlyReading.mock.id
        return Group {
            BookDetailWindow(dataModel: dataModel, bookId: .constant(bookId))
            BookDetailWindow(dataModel: dataModel, bookId: .constant(bookId))
                .environment(\.locale, .italian)
        }
    }
}
