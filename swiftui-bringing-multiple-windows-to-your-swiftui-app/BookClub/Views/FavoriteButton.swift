/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Favorite button to mark a currently reading book as favorited.
*/

import SwiftUI

struct FavoriteButton: View {
    var dataModel: ReadingListModel
    var bookId: Book.ID?
    
    var body: some View {
        Button {
            toggleIsFavorited()
        } label: {
            Label("Favorite", systemImage: "heart")
                .symbolVariant(isFavorited() ? .fill : .none)
        }
        .help("Favorite the book.")
        .disabled(bookId == nil || isWishlisted())
    }
    
    func toggleIsFavorited() {
        guard let bookId = bookId, let book = dataModel[book: bookId]
        else { return }
        book.isFavorited.toggle()
    }
    
    func isFavorited() -> Bool {
        guard let bookId = bookId, let book = dataModel[book: bookId]
        else { return false }
        return book.isFavorited
    }
    
    func isWishlisted() -> Bool {
        guard let bookId = bookId, let book = dataModel[book: bookId]
        else { return false }
        return book.isWishlisted
    }
}

struct FavoriteButton_Previews: PreviewProvider {
    static var previews: some View {
        let dataModel = ReadingListModel()
        return Group {
            FavoriteButton(dataModel: dataModel, bookId: nil)
            
            FavoriteButton(
                dataModel: dataModel,
                bookId: CurrentlyReading.mockFavorited.id)
            
            FavoriteButton(
                dataModel: dataModel,
                bookId: CurrentlyReading.mockWishlisted.id)
        }
    }
}
