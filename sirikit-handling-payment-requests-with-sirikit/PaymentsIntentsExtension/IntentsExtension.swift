/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main extension entry point.
*/

import Intents
import PaymentsFramework

class IntentsExtension: INExtension {

    let paymentProvider = PaymentProvider()
    let contactLookup = ContactLookup()

    /// - Tag: IntentHandler
    override func handler(for intent: INIntent) -> Any? {
        // This sample is only configured to handle `INSendPaymentIntent`.
        guard intent is INSendPaymentIntent
            else { preconditionFailure("Unhandled intent type \(intent)") }

        return SendPaymentIntentHandler(paymentProvider: paymentProvider, contactLookup: contactLookup)
    }

}
