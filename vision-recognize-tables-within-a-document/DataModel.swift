/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides data models to store information extracted from the document.
*/

import Vision
import SwiftUI

/// An object to represent the contact information for a person.
struct Contact {
    let name: String
    let email: String
    let phoneNumber: String?
}

/// A representation of a select cell within the table.
struct TableCell {
    /// Represents the type of data that is contained in the table cell.
    enum Content {
        /// An email address.
        case email(String)
        /// A phone number.
        case phone(String)
        /// A generic cell that is not an email or phone number.
        case text(String)
    }
    
    /// What information the cell contains.
    let content: Content
    /// The coordinates of the midpoint of the top line of the cell, normalized to the screen bounds.
    let location: UnitPoint
    
    /// Extracts content and location information.
    init(_ cell: DocumentObservation.Container.Table.Cell) {
        // Find out if the cell contains any emails or phone numbers.
        let detectedData = cell.content.text.detectedData.first
        switch detectedData?.match.details {
        case .emailAddress(let email):
            content = .email(email.emailAddress)
        case .phoneNumber(let phone):
            content = .phone(phone.phoneNumber)
        default:
            content = .text(cell.content.text.transcript)
        }
        // Get the bounding box of the cell in Vision coordinates.
        let boundingBox = cell.content.boundingRegion.boundingBox
        // Convert Vision coordinates to SwiftUI coordinates.
        let uiBoundingBox = boundingBox.verticallyFlipped()
        // Get the midpoint of the cell.
        let midPointX = uiBoundingBox.origin.x + uiBoundingBox.width / 2
        location = UnitPoint(x: midPointX, y: uiBoundingBox.origin.y)
    }
}
