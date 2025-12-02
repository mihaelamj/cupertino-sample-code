/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Share button to send book metadata to another application,
 with a share preview displaying a visual representation of the share data.
*/

import SwiftUI

struct ShareButton: View {
    var dataModel: ReadingListModel
    var bookId: Book.ID?
    
    var body: some View {
        Group {
            if let bookId = bookId,
               let currentlyReading = dataModel[book: bookId],
               let image = image(for: currentlyReading) {
                let byLine = currentlyReading.book.byLine
                    ShareLink(
                        item: image,
                        message: Text(byLine),
                        preview: SharePreview(byLine, image: image))
            } else {
                Button { } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(true)
            }
        }
        .help("Share the book with friends.")
    }
    
    @MainActor
    func image(for currentlyReading: CurrentlyReading) -> Image? {
        let book = currentlyReading.book
        let progress = currentlyReading.currentProgress
        let bookCard = BookCard(book: book, progress: progress)
        let renderer = ImageRenderer(content: bookCard)
        guard let cgImage = renderer.cgImage else { return nil }
        let label = Text(book.byLine)
        let image = Image(cgImage, scale: renderer.scale, label: label)
        return image.resizable()
    }
}

struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        let dataModel = ReadingListModel()
        return Group {
            ShareButton(dataModel: dataModel, bookId: nil)
            
            ShareButton(
                dataModel: dataModel,
                bookId: CurrentlyReading.mockFavorited.id)
            
            ShareButton(
                dataModel: dataModel,
                bookId: CurrentlyReading.mockWishlisted.id)
        }
    }
}
