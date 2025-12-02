/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting details about a purchase.
*/

import UIKit
import StoreKit

class PaymentTransactionDetails: BaseViewController {
    // MARK: - Types
    
    fileprivate struct CellIdentifiers {
        static let basic = "basic"
        static let custom = "custom"
    }
    
    // MARK: - Properties
    
    fileprivate var tableViewCellLabels: [SectionType: [String]] {
        let originalTransactions = [TransactionContentLabels.transactionIdentifier, TransactionContentLabels.transactionDate]
        
        return [.originalTransaction: originalTransactions]
    }
    
    // MARK: - UITable​View​Data​Source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = data[indexPath.section]
        
        if  section.type == .originalTransaction {
            return tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.custom, for: indexPath)
        } else {
            return tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.basic, for: indexPath)
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let section = data[indexPath.section]
        
        if section.type == .originalTransaction {
            let transactions = section.elements
            guard let dictionary = transactions[indexPath.row] as? [String: String] else { return }
            
            let items = tableViewCellLabels[section.type]
            guard let label = items?[indexPath.row] else { fatalError("\(Messages.unknownDetail) \(indexPath.row)).") }
            
            cell.textLabel!.text = label
            cell.detailTextLabel!.text = dictionary[label]
            
        } else {
            guard let details = section.elements as? [String] else { return }
            cell.textLabel!.text = details.first
        }
    }
}
