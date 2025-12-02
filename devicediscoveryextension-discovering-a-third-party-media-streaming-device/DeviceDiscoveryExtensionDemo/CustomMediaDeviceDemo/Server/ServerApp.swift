/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A companion server app.
*/

import SwiftUI
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		let audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession.setCategory(.playback, mode: .moviePlayback)
		} catch {
			print("Setting category to AVAudioSessionCategoryPlayback failed.")
		}
		return true
	}
}

@main
struct DataAccessDemoServerApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		WindowGroup {
			ServerView()
		}
	}
}
