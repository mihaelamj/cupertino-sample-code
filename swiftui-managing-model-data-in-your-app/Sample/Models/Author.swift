/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable data model for an author.
*/

import SwiftUI

@Observable final class Author: Identifiable {
    var name = "Sample Author"
}
