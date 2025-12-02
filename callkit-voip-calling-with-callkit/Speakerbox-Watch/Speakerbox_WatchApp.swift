/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main class for the Watch's SpeakerBox App
*/

import SwiftUI
import PushKit

@main
struct SpeakerboxWatchApp: App {
    @Environment(\.scenePhase) private var phase
    var callProvider = ProviderDelegate(callManager: SpeakerboxCallManager())
    
    init() {
        _ = PushRegistryDelegate(providerDelegate: callProvider)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(incomingCallback: { (handle: String, video: Bool) in
                callProvider.reportIncomingCall(uuid: UUID(), handle: handle, hasVideo: video) { _ in
    
                }
            }).onContinueUserActivity("INStartCallIntent", perform: { userActivity in
                guard let handle = userActivity.startCallHandle else {
                    print("Could not determine start call handle from user activity: \(userActivity)")
                    return
                }

                guard let video = userActivity.isVideo else {
                    print("Could not determine video from user activity: \(userActivity)")
                    return
                }

                SpeakerboxCallManager().startCall(handle: handle, video: video)
            })
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .active:
                // App became active
                break
            case .inactive:
                // App became inactive
                break
            case .background:
                // App is running in the background
                break
            @unknown default:
                // Fallback for future cases
                break
            }
        }
    }
}
