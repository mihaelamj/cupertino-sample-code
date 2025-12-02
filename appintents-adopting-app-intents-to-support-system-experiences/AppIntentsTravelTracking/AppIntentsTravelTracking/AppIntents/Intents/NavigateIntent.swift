/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to navigate to a section in the app.
*/

import AppIntents

struct NavigateIntent: AppIntent {
    static let title: LocalizedStringResource = "Navigate to Section"

    static let supportedModes: IntentModes = .foreground
    
    static var parameterSummary: some ParameterSummary {
        Summary("Navigate to \(\.$navigationOption)")
    }

    @Parameter(
        title: "Section",
        requestValueDialog: "Which section?"
    )
    var navigationOption: NavigationOption

    #if os(iOS)
    // You don't need to add code here to open the app
    // and navigate to the scene that matches the intent.
    // Instead, LandmarksSplitView` uses `.onAppIntentExecution()` view modifiers
    // for navigation.
    #elseif os(macOS)
    @Dependency var navigator: Navigator

    func perform() async throws -> some IntentResult {
        await navigator.navigate(to: navigationOption)

        return .result()
    }
    #endif

}

extension NavigateIntent {
    init(navigationOption: NavigationOption) {
        self.navigationOption = navigationOption
    }
}

#if os(iOS)
extension NavigateIntent: TargetContentProvidingIntent {}
#endif
