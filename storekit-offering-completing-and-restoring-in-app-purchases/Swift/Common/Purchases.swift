/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting purchased and restored products.
*/

import UIKit
import StoreKit

class Purchases: BaseViewController {
    // MARK: - Types
    
    fileprivate struct CellIdentifiers {
        static let purchase = "purchase"
    }
    
    fileprivate struct SegueIdentifiers {
        static let showPaymentTransaction = "showPaymentTransaction"
    }
    
    // MARK: - UITable​View​Data​Source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.purchase, for: indexPath)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let section = data[indexPath.section]
        
        if let purchases = section.elements  as? [SKPaymentTransaction] {
            let transaction = purchases[indexPath.row]
            let title = StoreManager.shared.title(matchingIdentifier: transaction.payment.productIdentifier)
            
            // Display the product's title associated with the payment's product identifier if it exists, or the product identifier, otherwise.
            cell.textLabel?.text = title ?? transaction.payment.productIdentifier
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedRowIndex = self.tableView.indexPathForSelectedRow else { fatalError("\(Messages.invalidIndexPath)") }
        
        guard let transactionDetails = segue.destination as? PaymentTransactionDetails, segue.identifier == SegueIdentifiers.showPaymentTransaction
            else { fatalError("\(Messages.unknownDestinationViewController)") }
        
        guard let purchases = data[selectedRowIndex.section].elements as? [SKPaymentTransaction] else { fatalError("\(Messages.unknownPurchase)") }
        let paymentTransaction = purchases[selectedRowIndex.row]
        
        #if os (iOS)
        let paymentTransactionDate = [DateFormatter.short(paymentTransaction.transactionDate!)]
        #else
        let paymentTransactionDate = [DateFormatter.long(paymentTransaction.transactionDate!)]
        #endif
        
        // Add the product identifier, transaction identifier, and transaction date to purchaseDetails.
        var purchaseDetails: [Section] = [Section(type: .productIdentifier, elements: [paymentTransaction.payment.productIdentifier]),
                                          Section(type: .transactionIdentifier, elements: [paymentTransaction.transactionIdentifier!]),
                                          Section(type: .transactionDate, elements: paymentTransactionDate)]
        
        // If the product is a restored one, add its original transaction's transaction identifier and transaction date to purchaseDetails.
        if let transactionIdentifier = paymentTransaction.original?.transactionIdentifier,
            let transactionDate = paymentTransaction.original?.transactionDate {
            let transactionID = [TransactionContentLabels.transactionIdentifier: transactionIdentifier]
            
            #if os (iOS)
            let transactionDateValue = [TransactionContentLabels.transactionDate: DateFormatter.short(transactionDate)]
            #else
            let transactionDateValue = [TransactionContentLabels.transactionDate: DateFormatter.long(transactionDate)]
            #endif
            
            purchaseDetails.append(Section(type: .originalTransaction, elements: [transactionID, transactionDateValue]))
        }
        
        transactionDetails.data = purchaseDetails
        transactionDetails.title = StoreManager.shared.title(matchingPaymentTransaction: paymentTransaction)
    }
}
