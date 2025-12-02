/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book context menu view when for quick actions.
*/

import SwiftUI

struct BookContextMenu: View {
    var dataModel: ReadingListModel
    var bookIds: Set<Book.ID>
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if supportsMultipleWindows {
            Section {
                Button {
                    bookIds.forEach { openWindow(value: $0) }
                } label: {
                    Label(
                    bookIds.count > 1 ? "Open Each in New Window" : "Open in New Window",
                    systemImage: "macwindow")
                }
            }
        }
        Section {
            let books = bookIds.compactMap { dataModel[book: $0] }
            Button {
                books.forEach { $0.markProgress(1.0) }
            } label: {
                Label(
                    bookIds.count > 1 ? "Mark All as Finished" : "Mark as Finished",
                    systemImage: "checkmark.square")
            }
            
            if bookIds.count == 1, let bookId = bookIds.first {
                FavoriteButton(dataModel: dataModel, bookId: bookId)
                ShareButton(dataModel: dataModel, bookId: bookId)
            } else {
                Button {
                    books.forEach { $0.isFavorited = true }
                } label: {
                    Label(
                        bookIds.count > 1 ? "Add All to Favorites" : "Add to Favorites",
                        systemImage: "heart")
                    .symbolVariant(
                        books.allSatisfy { $0.isFavorited }
                        ? .fill : .none)
                }
            }
        }
    }
}

struct BookContextMenu_Previews: PreviewProvider {
    static var previews: some View {
        let dataModel = ReadingListModel()
        let bookId = CurrentlyReading.mock.id
        return Group {
            BookContextMenu(dataModel: dataModel, bookIds: [bookId])
            BookContextMenu(dataModel: dataModel, bookIds: [bookId])
                .environment(\.locale, .italian)
        }
    }
}
