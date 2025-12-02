/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Write an extension delegate for the Tic-Tac-Toe watchOS app.
*/

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your app.
    }

    func applicationDidBecomeActive() {
        /* Restart any tasks that the system pauses or doesn't start while the app is inactive.
           If the app was previously in the background, optionally refresh the user interface. */
    }

    func applicationWillResignActive() {
        /* The system sends this when the app is about to move from an active to an inactive state. This can occur
         for certain types of temporary interruptions, (such as an incoming phone call or SMS message),
         or when the user quits the app and it begins the transition to the background state.
         Use this method to pause ongoing tasks, disable timers, and so forth. */
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        /* The system sends this when it needs to launch the app in the background to process tasks.
           Tasks arrive in a set, so loop through and process each one. */
        for task in backgroundTasks {
            // Use a switch statement to check the task type.
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task when you finish.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, so make sure to set your expiration date.
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task when you finish.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task when you finish.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task when you finish.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task when you finish.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // Make sure to complete unhandled task types.
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
