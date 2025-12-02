/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility file with custom errors that are localized and eligible for use in an intent.
*/

import Foundation

/**
 An intent can throw custom `Error` values. If the `Error` conforms to `CustomLocalizedStringResourceConvertible`, the system will use
 the localized text as part of the error handling.
 */
enum TrailIntentError: Error, CustomLocalizedStringResourceConvertible {
    case workoutDidNotStart
    case activeActivityNotFound
    case trailNotFound
    case dayPassTransactionCanceled
    case dayPassPaymentError
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .workoutDidNotStart:
            return "Workout tracking failed to start."
        case .activeActivityNotFound:
            return "Not currently tracking an activity."
        case .trailNotFound:
            return "Can't find the requested trail."
        case .dayPassTransactionCanceled:
            return "Your purchase was canceled."
        case .dayPassPaymentError:
            return "Unable to process payment."
        }
    }
}
