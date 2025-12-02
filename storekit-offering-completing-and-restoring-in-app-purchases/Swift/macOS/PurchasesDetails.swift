/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting details about a purchase.
*/

import Cocoa
import StoreKit

class PurchasesDetails: PrimaryViewController {
    // MARK: - Properties
    
    @IBOutlet weak fileprivate var stackView: NSStackView!
    @IBOutlet weak fileprivate var productID: NSTextField!
    @IBOutlet weak fileprivate var transactionID: NSTextField!
    @IBOutlet weak fileprivate var transactionDate: NSTextField!
        
    @IBOutlet weak fileprivate var originalTransaction: NSBox!
    @IBOutlet weak fileprivate var originalTransactionID: NSTextField!
    @IBOutlet weak fileprivate var originalTransactionDate: NSTextField!
    
    // MARK: - View Life Cycle
    
    override func viewDidAppear() {
        super.viewDidAppear()
        originalTransaction.hide()
        reloadTableAndSelectFirstRowIfNecessary()
    }
    
    // MARK: - Update UI
    
    /// Refreshes the UI with new payment transactions.
    func reload(with transactions: [SKPaymentTransaction]) {
        data = transactions
        self.tableView.reloadData()
        reloadTableAndSelectFirstRowIfNecessary()
    }
    
    /// Reloads the table view and programmatically selects a purchase.
    fileprivate func reloadTableAndSelectFirstRowIfNecessary() {
        // Select the first purchase and display its information if no row is currently in a selected state. Display the current selection, otherwise.
        let selection = (tableView.selectedRowIndexes.isEmpty) ? IndexSet(integer: 0) : tableView.selectedRowIndexes
        
        tableView.reloadData()
        tableView.selectRowIndexes(selection, byExtendingSelection: false)
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: nil) as? NSTableCellView,
            let transaction = data[row] as? SKPaymentTransaction else { return nil }
        
        // Display the product's title associated with the payment's product identifier.
        cell.textField?.stringValue = StoreManager.shared.title(matchingPaymentTransaction: transaction)
        return cell
    }
    
    /// Displays information about the selected purchase or a restored one.
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        guard (selectedRow >= 0) && (!data.isEmpty) else { return }
        
        originalTransaction.hide()
        
        guard let transaction = data[selectedRow] as? SKPaymentTransaction else { return }
        
        productID.stringValue = transaction.payment.productIdentifier
        transactionID.stringValue = transaction.transactionIdentifier!
        transactionDate.stringValue = DateFormatter.long(transaction.transactionDate!)
        
        // Display restored transactions if they exist.
        guard let transactionIdentifier = transaction.original?.transactionIdentifier, let transactionDate = transaction.original?.transactionDate
            else { return }
        
        originalTransaction.show()
        originalTransactionID.stringValue = transactionIdentifier
        originalTransactionDate.stringValue = DateFormatter.long(transactionDate)
    }
}

