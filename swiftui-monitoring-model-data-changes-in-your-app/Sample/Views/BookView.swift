/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the title of a book, as well as a button for editing the
 title.
*/

import SwiftUI

struct BookView: View {
    @ObservedObject var book: Book
    @State private var isEditorPresented = false
    
    var body: some View {
        HStack {
            Text(book.title)
            Spacer()
            Button("Edit") {
                isEditorPresented = true
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            BookEditView(book: book)
        }
    }
}

struct BookView_Previews: PreviewProvider {
    static var previews: some View {
        BookView(book: Book())
    }
}
