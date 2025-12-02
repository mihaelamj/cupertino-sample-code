/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension to allow creating a CallKit CXStartCallAction from an NSUserActivity that the app was launched with.
*/

import Foundation
import Intents

extension NSUserActivity: StartCallConvertible {

    var startCallHandle: String? {
        guard let startCallIntent = interaction?.intent as? INStartCallIntent,
            let personHandle = startCallIntent.contacts?.first?.personHandle
            else {
                return nil
        }

        return personHandle.value
    }

    var isVideo: Bool? {
        guard let startCallIntent = interaction?.intent as? INStartCallIntent else { return nil }
        return startCallIntent.callCapability == .videoCall
    }

}
