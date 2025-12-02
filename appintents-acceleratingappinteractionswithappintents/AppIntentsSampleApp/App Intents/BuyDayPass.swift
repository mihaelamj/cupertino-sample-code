/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent for making a purchase.
*/

import AppIntents
import Foundation
import OSLog

struct BuyDayPass: AppIntent {
    static let title: LocalizedStringResource = "Buy Day Pass"
    static let description = IntentDescription("Purchase a day pass for your trail activity with Apple Pay.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        /**
         Some types of intents need to confirm with people that they want to complete the action, such as intents involving a financial transaction.
         You can also provide your own `View` for the system to display as part of the confirmation prompt.
         */
        do {
            let passAmount = IntentCurrencyAmount(amount: 6.50, currencyCode: "USD")
            let confirmationDialog = IntentDialog("Are you sure you want to purchase a day pass for \(passAmount)?")
            
            Logger.intentLogging.debug("[BuyDayPass] About to request confirmation")
            
            /// Set a value for `confirmationActionName` that matches the action, such as `.buy` for a financial transaction.
            try await requestConfirmation(actionName: .buy, dialog: confirmationDialog)
            
            Logger.intentLogging.debug("[BuyDayPass] User confirmed they want to make the transaction")
        } catch {
            Logger.intentLogging.debug("[BuyDayPass] The user canceled the transaction at the confirmation step")
            
            /**
             Throw an error conforming to `CustomLocalizedStringResourceConvertible` so that the system presents the error with the
             customized error text.
             */
            throw TrailIntentError.dayPassTransactionCanceled
        }
        
        /**
         If taking a payment with Apple Pay, set up the `PKPaymentRequest` and then present the Apple Pay authorization after the
         confirmation, like this:
         ```
         let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
         guard await controller.present() else {
            throw TrailIntentError.dayPassPaymentError
         }
         ```
         */
        
        Logger.intentLogging.debug("[BuyDayPass] Transaction complete")
        return .result(dialog: "Your trail day pass is active.")
    }
}
