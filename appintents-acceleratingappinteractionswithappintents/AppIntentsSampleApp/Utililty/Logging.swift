/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility file for logging.
*/

import Foundation
import OSLog

extension Logger {
    static let intentLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "App Intent")
    static let entityQueryLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Entity Query")
    static let activityTracking = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Activity Tracking")
    static let spotlightLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Spotlight")
}
