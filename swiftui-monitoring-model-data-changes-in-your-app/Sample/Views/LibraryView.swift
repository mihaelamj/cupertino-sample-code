/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that lists the books available in the library.
*/

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var library: Library
    
    var body: some View {
        List(library.books) { book in
            BookView(book: book)
        }
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
            .environmentObject(Library())
    }
}
