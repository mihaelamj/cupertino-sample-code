/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Types that conform to the `IntentHandler` protocol can be queried as to whether they can handle a specific type of `INIntent`.
*/

import Intents

protocol IntentHandler: AnyObject {

    func canHandle(_ intent: INIntent) -> Bool

}
