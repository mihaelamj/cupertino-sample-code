/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
WiFiAware Errors.
*/

import Foundation
import WiFiAware

struct WiFiAwareError: LocalizedError {
    private let waError: WAError

    enum Category {
        case listener
        case browser
        case connection
    }
    private let category: Category

    init(_ waError: WAError, category: Category) {
        self.waError = waError
        self.category = category
    }

    var errorDescription: String? {
        switch category {
        case .listener: return "Listener Error"
        case .browser: return "Browser Error"
        case .connection: return "Connection Error"
        }
    }

    var recoverySuggestion: String? {
        switch waError {
        case .noPairedDevices(_): return "No Paired Devices. Tap + to pair."
        case .publisherTimeout(_): return "Timed out. Tap Advertise to restart."
        case .subscriberTimeout(_): return "Timed out. Tap Discover & Connect to restart."
        case .connectionIdleTimeout(_): return "Timed out due to inactivity. Try setting up a new connection."
        case .connectionFailed(_): return "Failed to connect. Try attempting the connection again."
        case .connectionTerminated(_): return "Connection terminated. Try setting up a new connection."
        default: return "Try again later."
        }
    }
}
