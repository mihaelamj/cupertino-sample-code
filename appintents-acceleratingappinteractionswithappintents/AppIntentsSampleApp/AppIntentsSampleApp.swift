/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The root app structure.
*/

import AppIntents
import SwiftUI

@main
struct AppIntentsSampleApp: App {
    
    private var trailManager: TrailDataManager
    private let sceneNavigationModel: NavigationModel
    private var accountManager: AccountManager
    private var activityManager: ActivityTracker
    
    init() {
        let trailDataManager = TrailDataManager.shared
        trailManager = trailDataManager
        
        let navigationModel = NavigationModel(selectedCollection: trailDataManager.nearMeCollection)
        sceneNavigationModel = navigationModel
        
        let accountDataManager = AccountManager.shared
        accountManager = accountDataManager
        
        let activityTracker = ActivityTracker.shared
        activityManager = activityTracker
        
        /**
         Register important objects that are required as dependencies of an `AppIntent` or an `EntityQuery`.
         The system automatically sets the value of properties in the intent or entity query to these values when the property is annotated with
         `@Dependency`. Intents that launch the app in the background won't have associated UI scenes, so the app must register these values
         as soon as possible in code paths that don't assume visible UI, such as the `App` initialization.
         */
        AppDependencyManager.shared.add(dependency: trailDataManager)
        AppDependencyManager.shared.add(dependency: navigationModel)
        AppDependencyManager.shared.add(dependency: accountDataManager)
        AppDependencyManager.shared.add(dependency: activityTracker)
        
        /**
         Call `updateAppShortcutParameters` on `AppShortcutsProvider` so that the system updates the App Shortcut phrases with any changes to
         the app's intent parameters. The app needs to call this function during its launch, in addition to any time the parameter values for
         the shortcut phrases change.
         */
        TrailShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(trailManager)
                .environment(sceneNavigationModel)
                .environment(accountManager)
                .environment(activityManager)
        }
    }
}
