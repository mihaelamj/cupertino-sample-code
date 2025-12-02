/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A struct that represents the contents of a textual document with a body and title.
*/

import Foundation

struct Document: Codable {
    var title = "New Document"
    var body = "Type or paste document body here"
}
