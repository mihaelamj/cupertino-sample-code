/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ErrorDetails represents a title and message to display in an Alert as an error occurs.
*/

import Foundation

struct ErrorDetails: Identifiable {
    let title: String
    let message: String
    let id = UUID()
}
