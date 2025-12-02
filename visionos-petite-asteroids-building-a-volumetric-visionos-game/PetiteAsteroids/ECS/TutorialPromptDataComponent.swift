/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component containing state data for the tutorial prompt view to observe.
*/
import RealityKit

struct TutorialPromptDataComponent: Component {
    var title: String? = nil
    var message: [JumpInputMode: String]? = nil
    var buttonLabel: String? = nil
    var buttonNotification: String? = nil
}
