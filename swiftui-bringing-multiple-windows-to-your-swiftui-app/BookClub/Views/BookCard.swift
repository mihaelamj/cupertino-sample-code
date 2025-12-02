/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book card view displaying the book title, author, and current reading progress.
*/

import SwiftUI

struct BookCard: View {
    var book: Book
    var progress: Double
    var isSelected: Bool = false
    
    var body: some View {
        HStack {
            BookCover(book: book, size: 120)
                .padding(.vertical, 4)
            VStack(alignment: .leading) {
                Text(book.title)
                    .lineLimit(3)
                    .font(.title3)
                    .fontWeight(.medium)
                Text(book.author)
                    .foregroundStyle(.secondary)
                LinearReadingProgressView(
                    value: progress,
                    isSelected: isSelected)
            }
            .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct BookCard_Previews: PreviewProvider {
    static var previews: some View {
        let book = CurrentlyReading.mock.book
        return Group {
            BookCard(book: book, progress: 0.5, isSelected: true)
            BookCard(book: book, progress: 0.5, isSelected: false)
        }
    }
}
