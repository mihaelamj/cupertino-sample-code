/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that implements `INSendPaymentIntentHandling` to handle `INSendPaymentIntent`.
*/

import Intents
import PaymentsFramework

class SendPaymentIntentHandler: NSObject, INSendPaymentIntentHandling {

    // MARK: Properties

    private let paymentProvider: PaymentProvider
    private let contactLookup: ContactLookup

    // MARK: Initialization

    init(paymentProvider: PaymentProvider, contactLookup: ContactLookup) {
        self.paymentProvider = paymentProvider
        self.contactLookup = contactLookup
    }

    // MARK: INSendPaymentIntentHandling parameter resolution

    /// - Tag: ResolvePayee
    func resolvePayee(for intent: INSendPaymentIntent, with completion: @escaping (INPersonResolutionResult) -> Void) {
        if let payee = intent.payee {
            // Look up contacts that match the payee.
            contactLookup.lookup(displayName: payee.displayName) { contacts in
                // Build the `INIntentResolutionResult` to pass to the `completion` closure.
                let result: INPersonResolutionResult

                if let contact = contacts.first, contacts.count == 1 {
                    // An exact single match.
                    let resolvedPayee = INPerson(contact: contact)
                    result = INPersonResolutionResult.success(with: resolvedPayee)
                } else if contacts.isEmpty {
                    // Found no matches.
                    result = INPersonResolutionResult.unsupported()
                } else {
                    // Found more than one match; user needs to clarify the intended contact.
                    let people: [INPerson] = contacts.map { contact in
                        return INPerson(contact: contact)
                    }
                    result = INPersonResolutionResult.disambiguation(with: people)
                }
                completion(result)
            }
        } else if let mostRecentPayee = paymentProvider.mostRecentPayment?.contact {
            // No payee provided; suggest the last payee.
            let result = INPersonResolutionResult.confirmationRequired(with: INPerson(contact: mostRecentPayee))
            completion(result)
        } else {
            // No payee provided and there was no previous payee.
            let result = INPersonResolutionResult.needsValue()
            completion(result)
        }
    }

    /// - Tag: ResolveCurrencyAmount
    func resolveCurrencyAmount(for intent: INSendPaymentIntent, with completion: @escaping (INCurrencyAmountResolutionResult) -> Void) {
        let result: INCurrencyAmountResolutionResult

        // Resolve the currency amount.
        if let currencyAmount = intent.currencyAmount, let amount = currencyAmount.amount, let currencyCode = currencyAmount.currencyCode {
            if amount.intValue <= 0 {
                // The amount needs to be a positive value.
                result = INCurrencyAmountResolutionResult.unsupported()
            } else if let currencyCode = paymentProvider.validate(currencyCode) {
                // Make a new `INCurrencyAmount` with the resolved currency code.
                let resolvedAmount = INCurrencyAmount(amount: amount, currencyCode: currencyCode)
                result = INCurrencyAmountResolutionResult.success(with: resolvedAmount)
            } else {
                // Unsupported currency.
                result = INCurrencyAmountResolutionResult.unsupported()
            }
        } else if let mostRecentPayment = paymentProvider.mostRecentPayment {
            // No amount provided; suggest the last amount sent.
            let suggestedAmount = INCurrencyAmount(amount: NSDecimalNumber(decimal: mostRecentPayment.amount),
                                                   currencyCode: mostRecentPayment.currencyCode)
            result = INCurrencyAmountResolutionResult.confirmationRequired(with: suggestedAmount)
        } else {
            // No amount provided and there was no previous payment.
            result = INCurrencyAmountResolutionResult.needsValue()
        }
        completion(result)
    }

    // MARK: INSendPaymentIntentHandling intent confirmation

    /// - Tag: ConfirmPayment
    func confirm(intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void) {
        guard
            let payee = intent.payee,
            let payeeHandle = payee.personHandle,
            let currencyAmount = intent.currencyAmount,
            let amount = currencyAmount.amount,
            let currencyCode = currencyAmount.currencyCode
            else { completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil)); return }

        contactLookup.lookup(emailAddress: payeeHandle.value!) { contact in
            guard let contact = contact else {
                completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                return
            }

            let payment = Payment(contact: contact, amount: amount.decimalValue, currencyCode: currencyCode)

            self.paymentProvider.canSend(payment) { success, error in
                guard success else {
                    completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                    return
                }

                let response = INSendPaymentIntentResponse(code: .success, userActivity: nil)
                response.paymentRecord = self.makePaymentRecord(for: intent)

                completion(response)
            }
        }
    }

    // MARK: INSendPaymentIntentHandling intent handling

    /// - Tag: HandlePayment
    func handle(intent: INSendPaymentIntent, completion: @escaping (INSendPaymentIntentResponse) -> Void) {
        guard
            let payee = intent.payee,
            let payeeHandle = payee.personHandle,
            let currencyAmount = intent.currencyAmount,
            let amount = currencyAmount.amount,
            let currencyCode = currencyAmount.currencyCode
            else { completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil)); return }

        contactLookup.lookup(emailAddress: payeeHandle.value!) { contact in
            guard let contact = contact else {
                completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                return
            }

            let payment = Payment(contact: contact, amount: amount.decimalValue, currencyCode: currencyCode)

            self.paymentProvider.send(payment) { success, _, _ in
                guard success else {
                    completion(INSendPaymentIntentResponse(code: .failure, userActivity: nil))
                    return
                }

                let response = INSendPaymentIntentResponse(code: .success, userActivity: nil)
                response.paymentRecord = self.makePaymentRecord(for: intent)

                completion(response)
            }
        }
    }

    // MARK: Convenience

    func makePaymentRecord(for intent: INSendPaymentIntent, status: INPaymentStatus = .completed) -> INPaymentRecord? {
        let paymentMethod = INPaymentMethod(type: .unknown, name: "Payments Sample", identificationHint: nil, icon: nil)
        return INPaymentRecord(payee: intent.payee, payer: nil, currencyAmount: intent.currencyAmount, paymentMethod: paymentMethod, note: intent.note, status: status)
    }

}
