/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides static methods to log messages to the unified logging system.
*/
import OSLog

struct AppLogger {
    static let logger = Logger(subsystem: "com.example.apple-samplecode.object-trackingt", category: "all")

    static func logError(_ msg: String) {
        logger.error("\(msg)")
    }

    static func logWarning(_ msg: String) {
        logger.warning("\(msg)")
    }

    static func logDebug(_ msg: String) {
        logger.debug("\(msg)")
    }

    static func logInfo(_ msg: String) {
        logger.info("\(msg)")
    }
}
