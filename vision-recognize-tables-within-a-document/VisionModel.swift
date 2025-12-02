/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides a class to detect and parse a table containing contact information.
*/

import SwiftUI
import Vision
import DataDetection

@Observable
class VisionModel {
    
    enum AppError: Error {
        case noDocument
        case noTable
        case invalidPoint
    }
    
    /// The first table detected in the document.
    var table: DocumentObservation.Container.Table? = nil
    /// A list of contacts extracted from the table.
    var contacts = [Contact]()
    
    /// Run Vision document recognition on the image to parse a table.
    func recognizeTable(in image: Data) async {
        resetState()
        do {
            let table = try await extractTable(from: image)
            self.table = table
            self.contacts = parseTable(table)
        } catch {
            print(error)
        }
    }
    
    /// Clear data from previous table detection.
    func resetState() {
        self.table = nil
        self.contacts = []
    }
    
    /// Convert a simple table into a TSV string format compatible with pasting into Notes & Numbers.
    ///
    /// Simple tables have at most 1 line per cell, and no cells that span multiple rows or columns.
    func exportTable() async throws -> String {
        guard let rows = self.table?.rows else {
            throw AppError.noTable
        }
        // Map each row into a tab-delimited line.
        let tableRowData = rows.map { row in
            return row.map({ $0.content.text.transcript }).joined(separator: "\t")
        }
        // Create a multiline string with one row per line.
        return tableRowData.joined(separator: "\n")
    }

    /// Process an image and return the first table detected.
    private func extractTable(from image: Data) async throws -> DocumentObservation.Container.Table {
        
        // The Vision request.
        let request = RecognizeDocumentsRequest()
        
        // Perform the request on the image data and return the results.
        let observations = try await request.perform(on: image)

        // Get the first observation from the array.
        guard let document = observations.first?.document else {
            throw AppError.noDocument
        }
        
        // Extract the first table detected.
        guard let table = document.tables.first else {
            throw AppError.noTable
        }
        
        return table
    }
    
    /// Extract name, email addresses, and phone number from a table into a list of contacts.
    private func parseTable(_ table: DocumentObservation.Container.Table) -> [Contact] {
        var contacts = [Contact]()
        
        // Iterate over each row in the table.
        for row in table.rows {
            // The contact name will be taken from the first column.
            guard let firstCell = row.first else {
                continue
            }
            // Extract the text content from the transcript.
            let name = firstCell.content.text.transcript
            
            // Look for emails and phone numbers in the remaining cells.
            var detectedPhone: String? = nil
            var detectedEmail: String? = nil
            
            for cell in row.dropFirst() {
                // Get all detected data in the cell, then match emails and phone numbers.
                for data in cell.content.text.detectedData {
                    switch data.match.details {
                    case .emailAddress(let email):
                        detectedEmail = email.emailAddress
                    case .phoneNumber(let phoneNumber):
                        detectedPhone = phoneNumber.phoneNumber
                    default:
                        break
                    }
                }
            }
            
            // Create a contact if an email was detected.
            if let email = detectedEmail {
                let contact = Contact(name: name, email: email, phoneNumber: detectedPhone)
                contacts.append(contact)
            }
        }
    
        return contacts
    }
}

extension DocumentObservation.Container.Table {
    /// Returns the contents of cell that a user clicked on.
    func cell(at point: NormalizedPoint) -> TableCell? {
        let visionPoint = point.cgPoint
        // Verify the point falls inside the bounding region of the table.
        guard self.boundingRegion.normalizedPath.contains(visionPoint) else {
            return nil
        }
        // Inspect each cell.
        for row in self.rows {
            for cell in row {
                // Check if the point falls inside the cell.
                if cell.content.boundingRegion.normalizedPath.contains(visionPoint) {
                    return TableCell(cell)
                }
            }
        }
        return nil
    }
}
