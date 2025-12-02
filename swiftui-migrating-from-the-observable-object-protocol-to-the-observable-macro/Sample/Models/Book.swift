/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable data model for a book.
*/

import SwiftUI

@Observable final class Book: Identifiable {
    var title = "Sample Book Title"
    
    let id = UUID() // A unique identifier that never changes.
}
