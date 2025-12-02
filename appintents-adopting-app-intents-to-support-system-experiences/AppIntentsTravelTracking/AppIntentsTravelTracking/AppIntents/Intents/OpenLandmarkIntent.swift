/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to open a landmark.
*/

import AppIntents

struct OpenLandmarkIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Landmark"

    @Parameter(title: "Landmark", requestValueDialog: "Which landmark?")
    var target: LandmarkEntity

    /**
     If your app intent conforms to the `OpenIntent` protocol and the intent's only
     functionality is to open the app to a specific scene,
     you don't have to implement your own perform() method in your iOS, iPadOS, or Mac app you built with Mac Catalyst.
     */
    #if os(macOS)
    @Dependency var navigator: Navigator

    func perform() async throws -> some IntentResult {

        await navigator.navigate(to: target)

        return .result()
    }
    #endif
}

#if os(iOS)
extension OpenLandmarkIntent: TargetContentProvidingIntent {}
#endif
