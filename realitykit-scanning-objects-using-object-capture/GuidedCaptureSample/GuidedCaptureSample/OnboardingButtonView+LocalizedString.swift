/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The localized strings used by OnboardingButtonView.
*/

import Foundation

extension OnboardingButtonView {
    struct LocalizedString {
        static let `continue` = NSLocalizedString(
            "Continue (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Continue",
            comment: "Title of button to continue to flip the object and capture more."
        )

        static let finish = NSLocalizedString(
            "Finish (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Finish",
            comment: "Title for finish button on the review screen."
        )

        static let process = NSLocalizedString(
            "Process (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Process",
            comment: "Title for process button on the review screen."
        )

        static let skip = NSLocalizedString(
            "Skip (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Skip",
            comment: "Title for skip button on the review screen."
        )

        static let cannotFlipYourObject = NSLocalizedString(
            "Can't flip your object? (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Can't flip your object?",
            comment: "Title for button on the object capture screen that lets users indicate that their object cannot be flipped."
        )

        static let flipAnyway = NSLocalizedString(
            "Flip object anyway (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Flip object anyway",
            comment: "Title for button on the object capture screen that lets users indicate they want to flip their object."
        )

        static let saveDraft = NSLocalizedString(
            "Save Draft (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Save Draft",
            comment: "Title for button to finish the session and run reconstruction later."
        )

        static let cancel = NSLocalizedString(
            "Cancel button (Object Capture, Review)",
            bundle: Bundle.main,
            value: "Cancel",
            comment: "Title of button to go back to capturing."
        )
    }
}
