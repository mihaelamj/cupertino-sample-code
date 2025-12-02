/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The WatchKit extension delegate.
*/

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    lazy var templateConfigurationURL: URL = {
        let urlOrNil = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        guard let documentsURL = urlOrNil else {
            fatalError("Failed to create the Docuemts folder!")
        }
        return documentsURL.appendingPathComponent("Configuration.json")
    }()

    lazy var templateConfiguration: TemplateConfiguration = {
        if FileManager.default.fileExists(atPath: templateConfigurationURL.path),
            let persistedConfiguration = TemplateConfiguration(from: templateConfigurationURL) {
            return persistedConfiguration
        }
        return TemplateConfiguration()
    }()
    
    lazy var timeline: Timeline = {
        return Timeline.demoTimeline()
    }()
    
    // A real-world app needs to update its complications from the background if, for example,
    // it needs to download data from a remote server and show the data on the watch faces.
    // You do this by implementing the following method. When the background download task
    // (URLSessionDownloadTask) is complete and the app isn't active at the moment, the system notifies
    // the app by waking it up or launching it in the background and calling this method with a
    // WKURLSessionRefreshBackgroundTask object. The app can then trigger a complication update by
    // calling CLKComplicationServer's reloadTimeline(for:) or extendTimeline(for:).
    //
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks.
        // Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
