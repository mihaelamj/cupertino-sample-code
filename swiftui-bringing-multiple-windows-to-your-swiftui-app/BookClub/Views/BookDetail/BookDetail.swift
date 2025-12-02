/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book detail view displaying the book detail view and action buttons.
*/

import SwiftUI

struct BookDetail: View {
    @ObservedObject var dataModel: ReadingListModel
    private var bookIds: [Selection]
    @State private var isPresented = false
    
    init(dataModel: ReadingListModel, bookIds: Set<Book.ID>) {
        self.dataModel = dataModel
        let selection = zip(0..., bookIds).map(Selection.init).sorted()
        self.bookIds = selection
    }

    var body: some View {
        ZStack {
            if bookIds.isEmpty {
                Text("No Book Selected")
                    .font(.title)
                    .foregroundStyle(.tertiary)
            } else if let firstBook = dataModel[book: bookIds[0].bookId] {
                if bookIds.count == 1 {
                    BookDetailContent(dataModel: dataModel, book: firstBook)
                    .navigationTitle(firstBook.book.title)
                    .toolbar {
                        ToolbarItemGroup(placement: .primaryAction) {
                            FavoriteButton(dataModel: dataModel, bookId: firstBook.id)
                            ShareButton(dataModel: dataModel, bookId: firstBook.id)
                        }
                        ToolbarItemGroup(placement: toolbarItemPlacement) {
                            Group {
                                UpdateReadingProgressButton(book: firstBook)
                                MarkAsFinishedButton(book: firstBook)
                            }
                            .labelStyle(.iconOnly)
                        }
                    }
                } else {
                    ZStack {
                        ForEach(bookIds, id: \.bookId) { selection in
                            if let book = dataModel[book: selection.bookId] {
                                BookDetailContent(dataModel: dataModel, book: book)
                                .cornerRadius(8)
                                .rotationEffect(.degrees(-2 * Double(selection.offset + 1)))
                                .scaleEffect(0.9)
                                .shadow(radius: 4)
                            }
                        }
                    }
                    .navigationTitle("\(bookIds.count) Books Selected")
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 480, idealWidth: 480)
        #endif
    }
    
    var toolbarItemPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .bottomBar
        #else
        return .secondaryAction
        #endif
    }
}

private struct Selection: Comparable, Hashable, Identifiable {
    var offset: Int
    var bookId: Book.ID
    
    var id: Book.ID { bookId }
    
    static func <(lhs: Selection, rhs: Selection) -> Bool {
        lhs.offset < rhs.offset
    }
}

struct BookDetail_Previews: PreviewProvider {
    static var previews: some View {
        let dataModel = ReadingListModel()
        let bookId = CurrentlyReading.mock.id
        return Group {
            BookDetail(dataModel: dataModel, bookIds: [])
            BookDetail(dataModel: dataModel, bookIds: [bookId])
            BookDetail(dataModel: dataModel, bookIds: [])
                .environment(\.locale, .italian)
            BookDetail(dataModel: dataModel, bookIds: [bookId])
                .environment(\.locale, .italian)
        }
    }
}
