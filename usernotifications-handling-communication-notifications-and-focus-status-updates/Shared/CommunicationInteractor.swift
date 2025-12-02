/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class in charge of interacting with Intents and UserNotifications frameworks.
*/

import Foundation
import UserNotifications
import Intents

enum CommunicationInteractorError: Error {
    case unexpectedIntentType
    case focusStatusNotAvailable
}

enum AuthorizationStatus {
    case notDetermined, restricted, denied, authorized, notSupported
}

class CommunicationInteractor {
    /// Outgoing messages and calls suggest people involved for Focus breakthrough.
    static func suggest(communicationInformation: CommunicationInformation,
                        completion: @escaping (Result<INInteraction, Error>) -> Void) {
        do {
            // Create an INInteraction.
            let interaction = try CommunicationMapper.interaction(communicationInformation: communicationInformation)
            // Donate INInteraction to the system.
            interaction.donate { [completion] error in
                DispatchQueue.global(qos: .userInitiated).async {
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(interaction))
                    }
                }
            }
        } catch let error {
            // Catch CommunicationMapper errors.
            completion(.failure(error))
        }
    }
    
    /// Update incoming notifications with a message or call information to allow the following:
    /// - Display an avatar, if present.
    /// - Check if sender is allowed to break through.
    /// - Update notification title (sender's name) and subtitle (group information).
    @available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
    static func update(notificationContent: UNNotificationContent,
                       communicationInformation: CommunicationInformation,
                       completion: @escaping (Result<UNNotificationContent, Error>) -> Void) {
        suggest(communicationInformation: communicationInformation) { [notificationContent] result in
            switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let interaction):
                    guard let notificationContentProvider = interaction.intent as? UNNotificationContentProviding else {
                        completion(.failure(CommunicationInteractorError.unexpectedIntentType))
                        return
                    }
                    do {
                        let updatedContent = try notificationContent.updating(from: notificationContentProvider)
                        completion(.success(updatedContent))
                    } catch let error {
                        completion(.failure(error))
                    }
            }
        }
    }
    
    /// Requests [.badge, .sound, .alert, .timeSensitive] user notifications authorization options.
    /// - Parameter completion: Result containing AuthorizationStatus or error.
    static func requestUserNotificationsAuthorization(completion: @escaping (Result<AuthorizationStatus, Error>) -> Void) {
        let authorizationOptions: UNAuthorizationOptions
        if #available(iOS 15, watchOS 8.0, macOS 12, *) {
            authorizationOptions = [.badge, .sound, .alert, .timeSensitive]
        } else {
            authorizationOptions = [.badge, .sound, .alert]
        }
        // Request authorization.
        UNUserNotificationCenter.current().requestAuthorization(options: authorizationOptions) { isGranted, error in
            if let error = error {
                completion(.failure(error))
            } else if !isGranted {
                completion(.success(.denied))
            } else {
                // Translate notification settings authorization status to AuthorizationStatus supported by this app.
                UNUserNotificationCenter.current().getNotificationSettings { notificationSettings in
                    switch notificationSettings.authorizationStatus {
                        case .notDetermined:
                            completion(.success(.notDetermined))
                        case .denied:
                            completion(.success(.denied))
                        case .authorized:
                            completion(.success(.authorized))
                        default:
                            completion(.success(.notSupported))
                    }
                }
            }
        }
    }
    
    /// Requests FocusStatusCenter authorization.
    /// Parameter completion: Result contains AuthorizationStatus or error.
    @available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
    static func requestFocusStatusAuthorization(completion: @escaping (Result<AuthorizationStatus, Error>) -> Void) {
        INFocusStatusCenter.default.requestAuthorization { status in
            switch status {
                case .denied:
                    completion(.success(.denied))
                case .authorized:
                    completion(.success(.authorized))
                case .notDetermined:
                    completion(.success(.notDetermined))
                case .restricted:
                    completion(.success(.restricted))
                @unknown default:
                    completion(.success(.notSupported))
            }
        }
    }
    
    /// Requests current focus status.
    /// Requires UserNotifications and FocusStatus to be authorized and Communication Notifications capability enabled for the app's target.
    /// Parameter completion: Result contains FocusStatus isFocused Bool, which will be true if Focus is enabled and this app
    /// isn't in its Allowed Apps list.
    @available(iOS 15.0, watchOS 8.0, macOS 12.0, *)
    static func requestFocusStatus(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let isFocused = INFocusStatusCenter.default.focusStatus.isFocused else {
            completion(.failure(CommunicationInteractorError.focusStatusNotAvailable))
            return
        }
        completion(.success(isFocused))
    }
}
