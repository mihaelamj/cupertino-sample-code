/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience accessors for information about the app.
*/

import Foundation

enum Constants {
  
  static var bundleIdentifier: String? = {
    Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
  }()
  
  static var bundleDisplayName: String? = {
    Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
  }()
  
  static var bundleShortVersionString: String? = {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  }()
  
  static var displayNameAndShortVersion: String {
    return "\(bundleDisplayName ?? "?") \(bundleShortVersionString ?? "#")"
  }
  
  static var logSubsystem = "BrowserExample"
}
