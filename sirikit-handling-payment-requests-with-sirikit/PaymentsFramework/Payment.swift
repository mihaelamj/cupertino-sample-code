/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A struct that defines a payment made with our app.
*/

import Foundation

public struct Payment {

    // MARK: Properties

    public let contact: Contact
    public let amount: Decimal
    public let currencyCode: String
    public let date: Date?

    // MARK: Public initializer

    public init(contact: Contact, amount: Decimal, currencyCode: String, date: Date? = nil) {
        self.contact = contact
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
    }
}

extension Payment: Equatable {}

extension Payment: Codable {}

/// Extend `Payment` with some sample payment data.

public extension Payment {

    static var samplePayments: [Payment] {
        // Generate three random sample payments to initialise with.
        return (1...3).map { index in
            guard let randomContact = Contact.sampleContacts.randomElement()
                else { preconditionFailure("Expected a valid contact.") }
            let randomAmount = Decimal(Int.random(in: 10...50))
            let date = Date(timeIntervalSinceNow: -Double.random(in: 1...86_400) + Double(index * 86_400))
            return Payment(contact: randomContact, amount: randomAmount, currencyCode: "USD", date: date)
        }
    }
}
