/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that the app uses to edit the title of a book.
*/

import SwiftUI

struct BookEditView: View {
    @ObservedObject var book: Book
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack() {
            TextField("Title", text: $book.title)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    dismiss()
                }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct BookEditView_Previews: PreviewProvider {
    static var previews: some View {
        BookEditView(book: Book())
    }
}
