/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller for identified business cards.
*/

import UIKit
import Vision

class BusinessCardContentsViewController: UITableViewController {
    static let tableCellIdentifier = "businessCardContentCell"

    typealias CardContentField = (name: String, value: String)

    /// The information to fetch from a scanned card.
    struct BusinessCardContents {
        
        var name: String?
        var numbers = [String]()
        var website: String?
        var address: String?
        var email: String?
        
        func availableContents() -> [CardContentField] {
            var contents = [CardContentField]()
     
            if let name = self.name {
                contents.append(("Name", name))
            }
            numbers.forEach { (number) in
                contents.append(("Number", number))
            }
            if let website = self.website {
                contents.append(("Website", website))
            }
            if let address = self.address {
                contents.append(("Address", address))
            }
            if let email = self.email {
                contents.append(("Email", email))
            }
            
            return contents
        }
    }
    
    var contents = BusinessCardContents()
}

// MARK: UITableViewDataSource
extension BusinessCardContentsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.availableContents().count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let field = contents.availableContents()[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier:
            BusinessCardContentsViewController.tableCellIdentifier, for: indexPath)
        cell.textLabel?.text = field.name
        cell.detailTextLabel?.text = field.value
        return cell
    }
}

// MARK: RecognizedTextDataSource
extension BusinessCardContentsViewController: RecognizedTextDataSource {
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        // Create a full transcript to run analysis on.
        var fullText = ""
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            fullText.append(candidate.string + "\n")
        }
        parseTextContents(text: fullText)
        tableView.reloadData()
        navigationItem.title = contents.name != nil ? contents.name : "Scanned Card"
    }
    
    // MARK: Helper functions
    func parseTextContents(text: String) {
        do {
            // Any line could contain the name on the business card.
            var potentialNames = text.components(separatedBy: .newlines)
            
            // Create an NSDataDetector to parse the text, searching for various fields of interest.
            let detector = try NSDataDetector(types: NSTextCheckingAllTypes)
            let matches = detector.matches(in: text, options: .init(), range: NSRange(location: 0, length: text.count))
            for match in matches {
                let matchStartIdx = text.index(text.startIndex, offsetBy: match.range.location)
                let matchEndIdx = text.index(text.startIndex, offsetBy: match.range.location + match.range.length)
                let matchedString = String(text[matchStartIdx..<matchEndIdx])
                
                // This line has been matched so it doesn't contain the name on the business card.
                while !potentialNames.isEmpty && (matchedString.contains(potentialNames[0]) || potentialNames[0].contains(matchedString)) {
                    potentialNames.remove(at: 0)
                }
            
                switch match.resultType {
                case .address:
                    contents.address = matchedString
                case .phoneNumber:
                    contents.numbers.append(matchedString)
                case .link:
                    if (match.url?.absoluteString.contains("mailto"))! {
                        contents.email = matchedString
                    } else {
                        contents.website = matchedString
                    }
                default:
                    print("\(matchedString) type:\(match.resultType)")
                }
            }
            if !potentialNames.isEmpty {
                // Take the top-most unmatched line to be the person/business name.
                contents.name = potentialNames.first
            }
        } catch {
            print(error)
        }
    }
}
