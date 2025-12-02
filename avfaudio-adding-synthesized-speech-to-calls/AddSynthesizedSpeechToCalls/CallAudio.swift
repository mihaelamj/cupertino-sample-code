/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable object that configures spoken audio injection and observes audio session state.
*/

import AVFAudio

@MainActor
@Observable
class CallAudio {
    
    /// A Boolean value that indicates whether a call is in progress.
    private(set) var isCallActive = false
    
    /// A Boolean value that indicates whether the audio session enables spoken audio injection.
    private var isAppAudioEnabled = false
    
    init() {
        // Create the shared audio session instance to receive notifications when its state changes.
        AVAudioSession.sharedInstance()
        // Set up audio session notification observations.
        Task { await observeCallState() }
        Task { await observeMediaServiceResets() }
    }
    
    /// Sets whether to include audio from the app in a phone or FaceTime call.
    ///
    /// - Parameter isEnabled: A Boolean value that indicates whether to enable spoken audio injection.
    /// - Returns: A Boolean value that indicates the enabled state of spoken audio injection; otherwise, an error.
    func setAppAudioEnabled(_ isEnabled: Bool) async -> Result<Bool, AppAudioError> {
        
        guard isEnabled else {
            // If the person disables spoken audio injection, set the mode back to its default value and return.
            setMicrophoneInjectionMode(.none)
            // Indicate the app successfully disabled spoken audio injection.
            return .success(false)
        }

        // Retrieve the current microphone injection permission and determine its state.
        let permission = AVAudioApplication.shared.microphoneInjectionPermission
        switch permission {
        case .serviceDisabled:
            // Indicate the system disables spoken audio injection globally.
            return .failure(.serviceDisabled)
        case .undetermined:
            // If undetermined, prompt the person to grant the app access, and turn on the feature, if allowed.
            if await AVAudioApplication.requestMicrophoneInjectionPermission() == .granted {
                setMicrophoneInjectionMode(.spokenAudio)
            }
        case .granted:
            // If a person grants permission, enable spoken audio injection.
            setMicrophoneInjectionMode(.spokenAudio)
        case .denied:
            // Indicate a person denied permission to use spoken audio injection.
            return .failure(.permissionDenied)
        @unknown default:
            print("Unknown microphone injection permission: \(permission)")
        }
        
        /// The value of `isInjectionEnabled` should be `true` at this point, unless an exception
        /// occurred when calling the audio session's `setPreferredMicrophoneInjectionMode(_:)` method.
        return isAppAudioEnabled ? .success(true) : .failure(.unknown)
    }
    
    private func setMicrophoneInjectionMode(_ mode: AVAudioSession.MicrophoneInjectionMode) {
        do {
            try AVAudioSession.sharedInstance().setPreferredMicrophoneInjectionMode(mode)
            // Set the state to true after successfully enabling spoken audio injection.
            isAppAudioEnabled = (mode == .spokenAudio)
            print("\(isAppAudioEnabled ? "Enabled" : "Disabled") spoken audio injection.")
        } catch {
            isAppAudioEnabled = false
            print("An error occurred setting the preferred microphone injection mode. \(error.localizedDescription)")
        }
    }
    
    /// Monitor the active state of phone and FaceTime calls.
    ///
    /// - Note: Apps must initialize the shared audio session instance to receive these notifications.
    private func observeCallState() async {
        /// Await notification of changes to the audio session's microphone injection capabilities.
        for await notification in NotificationCenter.default.notifications(named: AVAudioSession.microphoneInjectionCapabilitiesChangeNotification) {
            // Inspect the user information dictionary to determine whether microphone injection is available.
            isCallActive = notification.userInfo?[AVAudioSessionMicrophoneInjectionIsAvailableKey] as? Bool ?? false
        }
    }

    /// Monitor media services resets.
    ///
    /// - Note: Apps must initialize the shared audio session instance to receive these notifications.
    private func observeMediaServiceResets() async {
        // Await notification of the system resetting media services.
        for await notification in NotificationCenter.default.notifications(named: AVAudioSession.mediaServicesWereResetNotification) {
            print("The system reset media services; notification \(notification.name) received. userInfo=\(String(describing: notification.userInfo))")
            // If a person turned on audio injection before the system reset of media services, turn it on again.
            if isAppAudioEnabled {
                setMicrophoneInjectionMode(.spokenAudio)
            }
        }
    }
}

/// An error type that indicates failure conditions.
enum AppAudioError: Error {
    /// A person turns off this service for all apps.
    case serviceDisabled
    /// A person denied the app permission to use spoken audio injection.
    case permissionDenied
    /// An unknown error.
    case unknown
}
