/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for creating background tasks, shared by both targets.
*/

import Foundation
import ExposureNotification
import BackgroundTasks

let backgroundTaskIdentifier = Bundle.main.bundleIdentifier! + ".exposure-notification"

func createBackgroundTaskIfNeeded() {
    if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: .main) { task in
            
            // Notify the user if Bluetooth is off
            ExposureManager.shared.showBluetoothOffUserNotificationIfNeeded()
            
            // Perform the exposure detection
            let progress = ExposureManager.shared.detectExposures { success in
                task.setTaskCompleted(success: success)
            }
            
            // Handle running out of time
            task.expirationHandler = {
                progress.cancel()
                LocalStore.shared.exposureDetectionErrorLocalizedDescription = NSLocalizedString("BACKGROUND_TIMEOUT", comment: "Error")
            }
            
            // Schedule the next background task
            scheduleBackgroundTaskIfNeeded()
        }
    }
}

func scheduleBackgroundTaskIfNeeded() {
    if #available(iOS 13.5, *) {
        guard ENManager.authorizationStatus == .authorized else { return }
        let taskRequest = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        taskRequest.requiresNetworkConnectivity = true
        do {
            try BGTaskScheduler.shared.submit(taskRequest)
        } catch {
            print("Unable to schedule background task: \(error)")
        }
    }
}
