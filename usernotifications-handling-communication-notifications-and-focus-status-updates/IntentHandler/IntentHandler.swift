/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The principal class of the extension that implements the `INShareFocusStatusIntentHandling` protocol to receive Focus status updates.
*/

import Intents

/// Consider implementing INSendMessageIntentHandling and INStartCallIntentHandling
/// to handle Share Sheet and Siri requests.
class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        return self
    }
}

// MARK: - INShareFocusStatusIntentHandling

@available(iOSApplicationExtension 15.0, watchOSApplicationExtension 8.0, macOSApplicationExtension 12.0, *)
extension IntentHandler: INShareFocusStatusIntentHandling {
    
    /**
     For this Intent to be handled, the following requirements must be met:
     FocusStatusCenter authorized for parent app (target).
     UserNotifications authorized for parent app (target).
     Communication Notifications capability (entitlement) added to the parent app (target).
     */
    func handle(intent: INShareFocusStatusIntent, completion: @escaping (INShareFocusStatusIntentResponse) -> Void) {
        let response = INShareFocusStatusIntentResponse(code: .success, userActivity: nil)
        if let isFocused = intent.focusStatus?.isFocused {
            // Send isFocused value to servers or AppGroup.
            print("Is user focused: \(isFocused)")
        }
        completion(response)
    }
}
