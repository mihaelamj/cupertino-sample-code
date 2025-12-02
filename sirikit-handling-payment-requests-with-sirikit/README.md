# Handling Payment Requests with SiriKit

Add an Intent Extension to your app to handle money transfer requests with Siri.

## Overview

The app in this sample project demonstrates how to send payments between users by implementing [`INSendPaymentIntentHandling`](https://developer.apple.com/documentation/sirikit/insendpaymentintenthandling). Users can make payments with Siri and view a list of previously completed payments inside the main app.  

The project consists of three targets:

* `Payments`, an iOS app which shows a history of completed payments.
* `PaymentsIntentsExtension`, an Intent Extension that integrates with SiriKit to send payments.
* `PaymentsFramework`, an embedded framework containing shared code needed by both the Intent Extension and the main app.

See [Creating an Intents App Extension](https://developer.apple.com/documentation/sirikit/creating_an_intents_app_extension) for more information on the general process of adding an Intent Extension to your app, including how to enable the Siri capability and configure the `NSExtension` keys in the `Info.plist`.

## Configure the Sample Code Project

This sample app can be run in the iOS Simulator without any special setup, but in order to run on a device you will need to update the build settings and enable an App Group for the project:

1. Open `Payments.xcodeproj` with the latest version of Xcode.
2. In the project editor, set a new bundle identifier under Identity on the General pane for each of the three targets in the project.
3. In the Capabilities pane, make sure that App Groups is switched on for the `Payments` and `PaymentsIntentsExtension` targets.
4. Add an App Group identifier with the format `group.com.example`.
5. Reference the new App Group identifier in the source code. Open `PaymentProvider.swift` and modify the implementation of the `sharedUserDefaults` property to reference the new identifier.

- Note: Each target in the project must preface its bundle identifier with the bundle identifier of the app's main target. For example, if you set the bundle identifier for the `Payments` target to `com.example.Payments`, then you should set the bundle identifier for the `PaymentsIntentsExtension` target to `com.example.Payments.PaymentsIntentsExtension`.

## Resolve Payment Parameters

The first step in processing a payment with `INSendPaymentIntentHandling` is to obtain the payee for the transaction and the currency amount to send to the payee. Depending on the command that the user speaks to Siri, your app may have to deal with one of the following scenarios: 

* The initial request specifies all required parameters. For example, the user requests, "Send $50 to Jane with Payments."
* The request lacks some required parameters. For example, the user requests, "Send money to Jane with Payments."
* The request supplies incorrect or inaccurate parameters. For example, the user requests, "Send money to Dave with Payments," 
when no valid contacts match "Dave".
* The initial request supplies no parameters. For example, the user requests, "Send money with Payments."

The extension resolves each parameter separately by responding to methods from the [`INSendPaymentIntentHandling`](https://developer.apple.com/documentation/sirikit/insendpaymentintenthandling) protocol. Depending on the initial request and subsequent conversation with Siri, each of the parameter resolution methods may be called multiple times as Siri clarifies the request from the user.

The extension resolves the payee parameter through calls to [`resolvePayee(for:with:)`](https://developer.apple.com/documentation/sirikit/insendpaymentintenthandling/1638813-resolvepayee). Use this method to take input from Siri, match it to a payee, and asynchronously return an [`INPersonResolutionResult`](https://developer.apple.com/documentation/sirikit/inpersonresolutionresult) by calling [`success(with:)`](https://developer.apple.com/documentation/sirikit/inpersonresolutionresult/1902499-success), [`confirmationRequired(with:)`](https://developer.apple.com/documentation/sirikit/inpersonresolutionresult/1902496-confirmationrequired), [`disambiguation(with:)`](https://developer.apple.com/documentation/sirikit/inpersonresolutionresult/1902497-disambiguation), [`needsValue()`](https://developer.apple.com/documentation/sirikit/inintentresolutionresult/1902446-needsvalue), or [`unsupported()`](https://developer.apple.com/documentation/sirikit/inintentresolutionresult/2138302-unsupported).

``` swift
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
```
[View in Source](x-source-tag://ResolvePayee)

The extension resolves the currency amount for the payment through calls to [`resolveCurrencyAmount(for:with:)`](https://developer.apple.com/documentation/sirikit/insendpaymentintenthandling/1638362-resolvecurrencyamount), and optionally a note to be associated with the transaction is resolved with calls to [`resolveNote(for:with:)`](https://developer.apple.com/documentation/sirikit/insendpaymentintenthandling/1906905-resolvenote).

``` swift
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
```
[View in Source](x-source-tag://ResolveCurrencyAmount)

## Add Domain-Specific Language

Use [`INVocabulary`](https://developer.apple.com/documentation/sirikit/invocabulary) to aid Siri with recognizing any domain-specific vocabulary users are likely to use in their voice commands. For example, in this sample project payee names are not taken from the user's contacts but from a predefined list inside the app, so these names are added as additional vocabulary with [`setVocabularyStrings:ofType:`](https://developer.apple.com/documentation/sirikit/invocabulary/1638998-setvocabularystrings).

``` swift
// Register names of contacts that may not be in the user's address book.
let contactNames = Contact.sampleContacts.map { $0.formattedName }
INVocabulary.shared().setVocabularyStrings(NSOrderedSet(array: contactNames), of: .contactName)
```
[View in Source](x-source-tag://SetVocabularyStrings)

More information on the types of custom vocabulary that are appropriate to add to Siri can be found in [Registering Custom Vocabulary with SiriKit](https://developer.apple.com/documentation/sirikit/registering_custom_vocabulary_with_sirikit#2865079).

## Confirm and Complete the Payment

When all parameters have been resolved, the system calls [`confirm(intent:completion:)`](https://developer.apple.com/documentation/sirikit/insendpaymentintenthandling/1638929-confirm) to let the app validate the transaction details. Pass back the status of the transaction by calling the `completion` block with an [`INSendPaymentIntentResponse`](https://developer.apple.com/documentation/sirikit/insendpaymentintentresponse) object initialized from a [`INSendPaymentIntentResponseCode`](https://developer.apple.com/documentation/sirikit/insendpaymentintentresponsecode) and an [`INPaymentRecord`](https://developer.apple.com/documentation/sirikit/inpaymentrecord) in the [`paymentRecord`](https://developer.apple.com/documentation/sirikit/insendpaymentintentresponse/1638625-paymentrecord). 

``` swift
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
```
[View in Source](x-source-tag://ConfirmPayment)

Finally, once the payment has been confirmed by the user, the system calls [`handle(intent:completion:)`](https://developer.apple.com/documentation/sirikit/insendpaymentintenthandling/1638809-handle). Use this method to perform the confirmed transaction and pass back the status of the transaction by calling the `completion` block. 

``` swift
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
```
[View in Source](x-source-tag://HandlePayment)
