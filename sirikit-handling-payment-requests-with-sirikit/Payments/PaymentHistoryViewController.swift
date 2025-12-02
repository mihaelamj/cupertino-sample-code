/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that lists recent payments made with our app.
*/

import UIKit
import PaymentsFramework

class PaymentHistoryViewController: UITableViewController {

    private let paymentProvider = PaymentProvider()
    private var activeAppNotificationObserver: Any?

    private var payments = [Payment]() {
        didSet {
            // If a new array of `Payment` objects have been set, reload the table view.
            guard oldValue != payments && isViewLoaded else { return }
            tableView.reloadData()
        }
    }

    /// Used to format payment amounts in table view cells.

    private var amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    /// Used to format payment dates in table view cells.

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func loadPaymentHistory() {
        payments = paymentProvider.loadPaymentHistory().reversed()
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        loadPaymentHistory()

        let center = NotificationCenter.default
        let notification = UIApplication.didBecomeActiveNotification
        let queue = OperationQueue.main
        activeAppNotificationObserver = center.addObserver(forName: notification, object: nil, queue: queue) { [unowned self] (_) in
            self.loadPaymentHistory()
        }
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payments.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PaymentTableViewCell.reuseIdentifier, for: indexPath) as? PaymentTableViewCell
            else { preconditionFailure("Unable to dequeue a PaymentTableViewCell") }
        let payment = payments[indexPath.row]

        // Configure the cell with the payment details.
        cell.contactLabel.text = payment.contact.formattedName

        if let date = payment.date {
            cell.dateLabel.text = dateFormatter.string(from: date)
        } else {
            cell.dateLabel.text = "-"
        }

        amountFormatter.currencyCode = payment.currencyCode
        cell.amountLabel.text = amountFormatter.string(from: NSDecimalNumber(decimal: payment.amount))

        return cell
    }
}

/// Used by `PaymentHistoryViewController` to show details of a `Payment`.

class PaymentTableViewCell: UITableViewCell {

    static let reuseIdentifier = "PaymentTableViewCell"

    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!

}
