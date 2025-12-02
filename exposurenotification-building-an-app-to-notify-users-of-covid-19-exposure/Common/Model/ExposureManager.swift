/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that manages a singleton ENManager object.
*/

import Foundation
import ExposureNotification
import UserNotifications

class ExposureManager {
    
    static let shared = ExposureManager()
    
    let manager = ENManager()
    
    init() {
        if #available(iOS 13.5, *) {
            // In iOS 13.5 and later, the Background Tasks framework is available,
            // so create and schedule a background task for downloading keys and
            // detecting exposures
            createBackgroundTaskIfNeeded()
            scheduleBackgroundTaskIfNeeded()
        } else if ENManagerIsAvailable() {
            // If `ENManager` exists, and the iOS version is earlier than 13.5,
            // the app is running on iOS 12.5, where the Background Tasks
            // framework is unavailable. Specify an EN activity handler here, which
            // allows the app to receive background time for downloading keys
            // and looking for exposures when background tasks aren't available.
            // Apps should should call this method before calling activate().
            manager.setLaunchActivityHandler { (activityFlags) in
                // ENManager gives apps that register an activity handler
                // in iOS 12.5 up to 3.5 minutes of background time at
                // least once per day. In iOS 13 and later, registering an
                // activity handler does nothing.
                if activityFlags.contains(.periodicRun) {
                    print("Periodic activity callback called (iOS 12.5)")
                    _ = ExposureManager.shared.detectExposures()
                }
            }
        }
        manager.activate { _ in
            // Ensure Exposure Notifications is enabled if the app is authorized. The app
            // could get into a state where it is authorized, but Exposure Notifications
            // is not enabled, if the user initially denied Exposure Notifications
            // during onboarding, but then flipped on the "COVID-19 Exposure Notifications" switch
            // in Settings.
            if !self.manager.exposureNotificationEnabled {
                self.manager.setExposureNotificationEnabled(true) { (error) in
                    if let error = error {
                        print("Error attempting to enable on launch: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    deinit {
        manager.invalidate()
    }

    static let authorizationStatusChangeNotification = Notification.Name("ExposureManagerAuthorizationStatusChangedNotification")
    
    var detectingExposures = false
    
    func detectExposures(completionHandler: ((Bool) -> Void)? = nil) -> Progress {
        
        let progress = Progress()
        
        // Disallow concurrent exposure detection, because if allowed we might try to detect the same diagnosis keys more than once
        guard !detectingExposures else {
            completionHandler?(false)
            return progress
        }
        detectingExposures = true
        
        var localURLs = [URL]()
        
        func finish(_ result: Result<([Exposure], Int), Error>) {
            
            try? Server.shared.deleteDiagnosisKeyFile(at: localURLs)
            
            let success: Bool
            if progress.isCancelled {
                success = false
            } else {
                switch result {
                case let .success((newExposures, nextDiagnosisKeyFileIndex)):
                    LocalStore.shared.nextDiagnosisKeyFileIndex = nextDiagnosisKeyFileIndex
                    // Starting with the V2 API, ENManager will return cached results, so replace our saved results instead of appending
                    if #available(iOS 13.7, *) {
                        LocalStore.shared.exposures = newExposures
                    } else {
                        LocalStore.shared.exposures.append(contentsOf: newExposures)
                    }
                    LocalStore.shared.exposures.sort { $0.date < $1.date }
                    LocalStore.shared.dateLastPerformedExposureDetection = Date()
                    LocalStore.shared.exposureDetectionErrorLocalizedDescription = nil
                    success = true
                case let .failure(error):
                    LocalStore.shared.exposureDetectionErrorLocalizedDescription = error.localizedDescription
                    // Consider posting a user notification that an error occured
                    success = false
                }
            }
            
            detectingExposures = false
            completionHandler?(success)
        }
        // Handles getting exposures using the version 2 API in iOS 13.7+ and
        // in iOS 12.5
        func getExposuresV2(_ summary: ENExposureDetectionSummary) {
            self.manager.getExposureWindows(summary: summary) { windows, error in
                if let error = error {
                    finish(.failure(error))
                    return
                }
                let allWindows = windows!.map { window in
                    Exposure(date: window.date)
                }
                finish(.success((allWindows, nextDiagnosisKeyFileIndex + localURLs.count)))
            }
        }
        
        // Handles getting exposures using the version 1 API used in iOS 13.5 and iOS 13.6
        @available(iOS 13.5, *)
        func getExposuresV1(_ summary: ENExposureDetectionSummary) {
            let userExplanation = NSLocalizedString("USER_NOTIFICATION_EXPLANATION", comment: "User notification")
            ExposureManager.shared.manager.getExposureInfo(summary: summary,
                                                           userExplanation: userExplanation) { exposures, error in
                if let error = error {
                    finish(.failure(error))
                    return
                }
                let newExposures = exposures!.map { exposure in
                    Exposure(date: exposure.date)
                }
                finish(.success((newExposures, nextDiagnosisKeyFileIndex + localURLs.count)))
            }
        }
        
        let nextDiagnosisKeyFileIndex = LocalStore.shared.nextDiagnosisKeyFileIndex
        
        Server.shared.getDiagnosisKeyFileURLs(startingAt: nextDiagnosisKeyFileIndex) { result in
            
            let dispatchGroup = DispatchGroup()
            var localURLResults = [Result<[URL], Error>]()
            
            switch result {
            case let .success(remoteURLs):
                for remoteURL in remoteURLs {
                    dispatchGroup.enter()
                    Server.shared.downloadDiagnosisKeyFile(at: remoteURL) { result in
                        localURLResults.append(result)
                        dispatchGroup.leave()
                    }
                }
                
            case let .failure(error):
                finish(.failure(error))
            }
            dispatchGroup.notify(queue: .main) {
                for result in localURLResults {
                    switch result {
                    case let .success(urls):
                        localURLs.append(contentsOf: urls)
                    case let .failure(error):
                        finish(.failure(error))
                        return
                    }
                }
                Server.shared.getExposureConfiguration { result in
                    switch result {
                    case let .success(configuration):
                        ExposureManager.shared.manager.detectExposures(configuration: configuration, diagnosisKeyURLs: localURLs) { summary, error in
                            if let error = error {
                                finish(.failure(error))
                                return
                            }
                            if #available(iOS 13.7, *) {
                                getExposuresV2(summary!)
                            } else if #available(iOS 13.5, *) {
                                getExposuresV1(summary!)
                            } else if ENManagerIsAvailable() {
                                getExposuresV2(summary!)
                            } else {
                                print("Exposure Notifications not supported on this version of iOS.")
                            }
                        }
                        
                    case let .failure(error):
                        finish(.failure(error))
                    }
                }
            }
        }
        
        return progress
    }

    func getAndPostDiagnosisKeys(testResult: TestResult, completion: @escaping (Error?) -> Void) {
        manager.getDiagnosisKeys { temporaryExposureKeys, error in
            if let error = error {
                completion(error)
            } else {
                guard let temporaryExposureKeys = temporaryExposureKeys else {
                    print("No exposure keys, aborting key share")
                    return
                }
                
                // In this sample app, transmissionRiskLevel isn't set for any of the diagnosis keys. However, it is at this point that an app could
                // use information accumulated in testResult to determine a transmissionRiskLevel for each diagnosis key.
                Server.shared.postDiagnosisKeys(temporaryExposureKeys) { error in
                    completion(error)
                }
            }
        }
    }
    
    // Includes today's key, requires com.apple.developer.exposure-notification-test entitlement
    func getAndPostTestDiagnosisKeys(completion: @escaping (Error?) -> Void) {
        manager.getTestDiagnosisKeys { temporaryExposureKeys, error in
            if let error = error {
                completion(error)
            } else {
                Server.shared.postDiagnosisKeys(temporaryExposureKeys!) { error in
                    completion(error)
                }
            }
        }
    }
    
    func showBluetoothOffUserNotificationIfNeeded() {
        let identifier = "bluetooth-off"
        if ENManager.authorizationStatus == .authorized && manager.exposureNotificationStatus == .bluetoothOff {
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("USER_NOTIFICATION_BLUETOOTH_OFF_TITLE", comment: "User notification title")
            content.body = NSLocalizedString("USER_NOTIFICATION_BLUETOOTH_OFF_BODY", comment: "User notification")
            content.sound = .default
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error showing error user notification: \(error)")
                    }
                }
            }
        } else {
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        }
    }

    @available(iOS 14.4, *)
    func preAuthorizeKeys(
        completion: @escaping (Error?) -> Void) {
        manager.preAuthorizeDiagnosisKeys { (error) in
            if let error = error {
                print("Error pre-authorizing keys: \(error)")
                completion(error)
                return
            }
            print("Successfully pre-authorized keys")
            completion(nil)
        }
    }
    
    @available(iOS 14.4, *)
    func requestAndPostPreAuthorizedKeys(
        completion: @escaping (Error?) -> Void) {
        // This handler receives preauthorized keys. Once the handler is called,
        // the preauthorization expires, so the handler should only be called
        // once per preauthorization request. If the user doesn't authorize
        // release, this handler isn't called.
        manager.diagnosisKeysAvailableHandler = { (keys) in
            Server.shared.postDiagnosisKeys(keys) { (error) in
                if let error = error {
                    print("Error posting pre-authorized diagnosis keys: \(error)")
                }
                completion(error)
            }
        }
        
        // This call requests preauthorized keys. The request fails if the
        // user doesn't authorize release or if more than five days pass after
        // authorization. If requestPreAuthorizedDiagnosisKeys(:) has already
        // been called since the last time the user preauthorized, the call
        // doesn't fail but also doesn't return any keys.
        manager.requestPreAuthorizedDiagnosisKeys { (error) in
            if let error = error {
                print("Error retrieving pre-authorized diganosis keys: \(error)")
                completion(error)
            }
        }
    }
    
}
