/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class tha mimics asynchronous calls to send payments to a server.
*/

import Foundation

public class PaymentProvider {

    // MARK: Properties

    public var mostRecentPayment: Payment? {
        let paymentHistory = loadPaymentHistory()
        return paymentHistory.last
    }

    // MARK: Intialization

    public init() {}

    // MARK: Payment methods

    public func canSend(_ payment: Payment, completion: (_ success: Bool, _ error: NSError?) -> Void) {
        // Accept any payment for the purposes of this sample.
        completion(true, nil)
    }

    public func send(_ payment: Payment, completion: (_ success: Bool, _ sentPayment: Payment?, _ error: NSError?) -> Void) {
        // Accept any payment for the purposes of this sample.

        // Create a new `Payment` that includes the current date as the date it was made.
        let datedPayment = Payment(contact: payment.contact, amount: payment.amount, currencyCode: payment.currencyCode, date: Date())

        // Add the dated payment to the payment history and save it.
        var paymentHistory = loadPaymentHistory()
        paymentHistory.append(datedPayment)
        save(paymentHistory)

        // Call the completion handler.
        completion(true, datedPayment, nil)
    }

    // MARK: Convenience

    public func validate(_ currencyCode: String) -> String? {
        if currencyCode == "USD" || currencyCode == "AMBIGUOUS_DOLLAR" {
            return "USD"
        } else {
            return nil
        }
    }

    public func loadPaymentHistory() -> [Payment] {
        var paymentHistory = [Payment]()

        if let archivedData = sharedUserDefaults.data(forKey: "paymentHistory") {
            do {
                let decoder = PropertyListDecoder()
                paymentHistory = try decoder.decode([Payment].self, from: archivedData)
            } catch let error as NSError {
                fatalError("Error decoding data: \(error)")
            }
        }

        // If no stored data was loaded, seed with some sample data.
        if paymentHistory.count < 1 {
            paymentHistory = Payment.samplePayments
            save(paymentHistory)
        }

        return paymentHistory
    }

    private func save(_ payments: [Payment]) {
        // Make sure the number of payments isn't too large
        let paymentsToSave = Array(payments.suffix(50))

        do {
            let encoder = PropertyListEncoder()
            let data = try encoder.encode(paymentsToSave)
            sharedUserDefaults.set(data, forKey: "paymentHistory")

        } catch let error as NSError {
            fatalError("Error encoding data: \(error)")
        }
    }

    private var sharedUserDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: "group.com.example.apple-samplecode.Payments")
            else { preconditionFailure("Unable to make shared NSUserDefaults object") }
        return defaults
    }

}
