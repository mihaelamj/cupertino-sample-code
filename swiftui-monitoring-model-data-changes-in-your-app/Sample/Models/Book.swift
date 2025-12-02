/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable data model for a book.
*/

import SwiftUI

class Book: ObservableObject, Identifiable {
    @Published var title = "Sample Book Title"
    
    let id = UUID() // A unique identifier that never changes.
}
