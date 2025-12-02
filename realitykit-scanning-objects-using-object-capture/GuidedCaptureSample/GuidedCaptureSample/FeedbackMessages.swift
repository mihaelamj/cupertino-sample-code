/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that generates human-readable strings for each Feedback state.
*/

import RealityKit
import SwiftUI

/// Keeps the UI string conversions all in one place for simplicity
final class FeedbackMessages {
    /// Returns the human readable string to display for the given feedback.  If there are more than one feedback entries, they
    /// will be concatenated together on multi-lines ('\n\ separated).
    static func getFeedbackString(for feedback: ObjectCaptureSession.Feedback, captureMode: AppDataModel.CaptureMode) -> String? {
           switch feedback {
               case .objectTooFar:
                   if captureMode == .area { return nil }
                   return NSLocalizedString(
                    "Move Closer (Object Capture)",
                    bundle: Bundle.main,
                    value: "Move Closer",
                    comment: "Feedback message to move closer for object capture")
               case .objectTooClose:
                   if captureMode == .area { return nil }
                   return NSLocalizedString(
                    "Move Farther Away (Object Capture)",
                    bundle: Bundle.main,
                    value: "Move Farther Away",
                    comment: "Feedback message to move back for object capture")
               case .environmentTooDark:
                   return NSLocalizedString(
                    "More Light Required (Object Capture)",
                    bundle: Bundle.main,
                    value: "More Light Required",
                    comment: "Feedback message that shows the environment is too dark for capturing")
               case .environmentLowLight:
                   return NSLocalizedString(
                    "More Light Recommended (Object Capture)",
                    bundle: Bundle.main,
                    value: "More Light Recommended",
                    comment: "Feedback message to increase lighting for object capture")
               case .movingTooFast:
                   return NSLocalizedString(
                    "Move slower (Object Capture)",
                    bundle: Bundle.main,
                    value: "Move slower",
                    comment: "Feedback message to slow down for object capture")
               case .outOfFieldOfView:
                   return NSLocalizedString(
                    "Aim at your object (Object Capture)",
                    bundle: Bundle.main,
                    value: "Aim at your object",
                    comment: "Feedback message to aim at your object for object capture")
               default: return nil
           }
    }
}

