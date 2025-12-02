/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The `IntentHandler` that vends instances of `OrderSoupIntentHandler` for iOS.
*/
import Intents
import SoupKit

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        guard intent is OrderSoupIntent else {
            fatalError("Unhandled intent type: \(intent)")
        }
        return OrderSoupIntentHandler()
    }
}

