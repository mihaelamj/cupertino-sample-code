/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Viewcontroller for scanned receipts.
*/

import UIKit
import Vision

class ReceiptContentsViewController: UITableViewController {

    static let tableCellIdentifier = "receiptContentCell"

    // Use this height value to differentiate between big labels and small labels in a receipt.
    static let textHeightThreshold: CGFloat = 0.025
    
    typealias ReceiptContentField = (name: String, value: String)

    // The information to fetch from a scanned receipt.
    struct ReceiptContents {

        var name: String?
        var items = [ReceiptContentField]()
    }
    
    var contents = ReceiptContents()
}

// MARK: UITableViewDataSource
extension ReceiptContentsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let field = contents.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptContentsViewController.tableCellIdentifier, for: indexPath)
        cell.textLabel?.text = field.name
        cell.detailTextLabel?.text = field.value
        print("\(field.name)\t\(field.value)")
        return cell
    }
}
    
    // MARK: RecognizedTextDataSource
extension ReceiptContentsViewController: RecognizedTextDataSource {
    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        // Create a full transcript to run analysis on.
        var currLabel: String?
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            let isLarge = (observation.boundingBox.height > ReceiptContentsViewController.textHeightThreshold)
            var text = candidate.string
            // The value might be preceded by a qualifier (e.g A small '3x' preceding 'Additional shot'.)
            var valueQualifier: VNRecognizedTextObservation?

            if isLarge {
                if let label = currLabel {
                    if let qualifier = valueQualifier {
                        if abs(qualifier.boundingBox.minY - observation.boundingBox.minY) < 0.01 {
                            // The qualifier's baseline is within 1% of the current observation's baseline, it must belong to the current value.
                            let qualifierCandidate = qualifier.topCandidates(1)[0]
                            text = qualifierCandidate.string + " " + text
                        }
                        valueQualifier = nil
                    }
                    contents.items.append((label, text))
                    currLabel = nil
                } else if contents.name == nil && observation.boundingBox.minX < 0.5 && text.count >= 2 {
                    // Name is located on the top-left of the receipt.
                    contents.name = text
                }
            } else {
                if text.starts(with: "#") {
                    // Order number is the only thing that starts with #.
                    contents.items.append(("Order", text))
                } else if currLabel == nil {
                    currLabel = text
                } else {
                    do {
                        // Create an NSDataDetector to detect whether there is a date in the string.
                        let types: NSTextCheckingResult.CheckingType = [.date]
                        let detector = try NSDataDetector(types: types.rawValue)
                        let matches = detector.matches(in: text, options: .init(), range: NSRange(location: 0, length: text.count))
                        if !matches.isEmpty {
                            contents.items.append(("Date", text))
                        } else {
                            // This observation is potentially a qualifier.
                            valueQualifier = observation
                        }
                    } catch {
                        print(error)
                    }

                }
            }
        }
        tableView.reloadData()
        navigationItem.title = contents.name != nil ? contents.name : "Scanned Receipt"
    }
}
