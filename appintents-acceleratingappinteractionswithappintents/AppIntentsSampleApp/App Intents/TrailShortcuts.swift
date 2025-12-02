/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An array of intents that the app makes available as App Shortcuts.
*/

import Foundation
import AppIntents

/**
 An `AppShortcut` wraps an intent to make it automatically discoverable throughout the system. An `AppShortcutsProvider` manages the shortcuts the app
 makes available. The app can update the available shortcuts by calling `updateAppShortcutParameters()` as needed.
 */
struct TrailShortcuts: AppShortcutsProvider {
    
    /// The color the system uses to display the App Shortcuts in the Shortcuts app.
    static let shortcutTileColor = ShortcutTileColor.navy
    
    /**
     This sample app contains several examples of different intents, but only the intents this array describes make sense as App Shortcuts.
     Put the App Shortcut most people will use as the first item in the array. This first shortcut shouldn't bring the app to the foreground.
     
     Each phrase that people use to invoke an App Shortcut needs to contain the app name, using the `applicationName` placeholder in the provided
     phrase text, as well as any app name synonyms you declare in the `INAlternativeAppNames` key of the app's `Info.plist` file. You localize these
     phrases in a string catalog named `AppShortcuts.xcstrings`.
     
     - Tag: open_favorites_app_shortcut
     */
    static var appShortcuts: [AppShortcut] {
        /**
         Records activity on a trail, such as hiking. On Apple Watch, `StartTrailActivity` creates a workout session.
         
         Use the `$workoutStyle` parameter from the intent to allow people to ask the app to start tracking an activity by the
         activity name. The system creates an App Shortcut for each possible value in the `ActivityStyle` enumeration. The complete set of
         generated App Shortcuts for this intent are visible in the Shortcuts app, or by following the `ShortcutsLink` at the bottom of
         `SidebarColumn`.
         */
        AppShortcut(intent: StartTrailActivity(), phrases: [
            "Track my \(\.$workoutStyle) in \(.applicationName)",
            "Start tracking my \(\.$workoutStyle) with \(.applicationName)",
            "Start a workout in \(.applicationName)",
            "Start a \(.applicationName) workout"
        ],
        shortTitle: "Start Activity",
        systemImageName: "shoeprints.fill")
        
        /// `GetTrailInfo` allows people to quickly check the conditions on their favorite trails.
        AppShortcut(intent: GetTrailInfo(), phrases: [
            "Get \(\.$trail) conditions with \(.applicationName)",
            "Get conditions on \(\.$trail) with \(.applicationName)"
        ],
        shortTitle: "Get Conditions",
        systemImageName: "cloud.rainbow.half",
        parameterPresentation: ParameterPresentation(
            for: \.$trail,
            summary: Summary("Get \(\.$trail) conditions"),
            optionsCollections: {
                OptionsCollection(TrailEntityQuery(), title: "Favorite Trails", systemImageName: "cloud.rainbow.half")
            }
        ))
        
        /// `OpenFavorites` brings the app to the foreground and displays the contents of the Favorite Trails collection in the UI.
        AppShortcut(intent: OpenFavorites(), phrases: [
            "Open Favorites in \(.applicationName)",
            "Show my favorite \(.applicationName)"
        ],
        shortTitle: "Open Favorites",
        systemImageName: "star.circle")
        
        /// `BuyDayPass` allows people to purchase a day pass, as an example of a routine purchase that people may frequently perform.
        AppShortcut(intent: BuyDayPass(), phrases: [
            "Buy a \(.applicationName) day pass",
            "Purchase a pass in \(.applicationName)"
        ],
        shortTitle: "Buy Day Pass",
        systemImageName: "wallet.pass")
    }
}
