/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent that opens the app and navigates to a specific trail.
*/

import Foundation
import AppIntents

/**
 People can open specific trails directly in the app. Because `TrailEntity` conforms to `URLRepresentableEntity`,
 that enables people to use a Universal Link to open the app directly to the trail, including from a shortcut.
 
 - Note: This sample project focuses only on the code required to integrate Universal Links with App Intents.
 For more information about creating a full implementation of universal links in an app, including app-based URL handling and setting up
 the requirements on your website, see
 [Supporting universal links in your app](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app).
 Because those elements aren't part of this sample, this intent opens the URL that `TrailEntity`declares  in Safari rather than the app.
 */
struct OpenTrail: OpenIntent, URLRepresentableIntent {
    
    static let title: LocalizedStringResource = "Open Trail"

    static let description = IntentDescription("Displays trail details in the app.")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }
    
    /// `OpenIntent` requires a `target` property to represent the entity opening in the app.
    @Parameter(title: "Trail")
    var target: TrailEntity
    
    /// Because this intent conforms to `OpenIntent`, the system opens the app when the intent runs,
    /// so you don't need to implement the `openAppWhenRun`property.
    // static var openAppWhenRun: Bool = true
    
    /**
     This intent doesn't need a `perform()` method because it conforms to `URLRepresentableIntent`.
     When this intent runs, the system takes the URL that `target` declares through its `URLRepresentableEntity` conformance,
     and calls the standard path for opening a universal link URL in the app using that URL.
     */
    // @MainActor func perform() async throws -> some IntentResult { }
}
