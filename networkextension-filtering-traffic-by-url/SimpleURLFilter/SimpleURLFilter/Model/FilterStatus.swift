/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
FilterStatus represents the status, and any associated error message, of the NEURLFilterManager.
*/

import Foundation
import NetworkExtension
import OSLog

public enum FilterStatus: Equatable {
    // "No status, or an unhandled status, from the system."
    case unknown(errorMessage: String?)

    // Configuration is present, but disabled.
    // This is a meta-status which is derrived from a combination of the underlying
    // NEURLFilterManager.Status, and the NEURLFilterManager.isEnabled property.
    case disabled

    // "The URL filter is not configured."
    case invalid

    // "The URL filter is not running."
    case stopped(errorMessage: String?)

    // "The URL filter is starting."
    case starting

    // "The URL filter is running."
    case running

    // "The URL filter is stopping."
    case stopping(errorMessage: String?)

    init(status: NEURLFilterManager.Status, configuration: Configuration?) async {
        switch status {
        case .invalid:
            // The 'invalid' status can either mean there is no configuration,
            // or that the configuration is present, but in a disabled state.
            guard let configuration, configuration.valid else {
                self = .invalid
                return
            }
            self = .disabled
        case .stopped:
            let errorMessage = await Self.fetchErrorMessage()
            self = .stopped(errorMessage: errorMessage)
        case .starting:
            self = .starting
        case .running:
            self = .running
        case .stopping:
            let errorMessage = await Self.fetchErrorMessage()
            self = .stopping(errorMessage: errorMessage)
        @unknown default:
            let log = Logger.createLogger(for: Self.self)
            log.error("Unhandled NEURLFilterManager.Status: \(status.rawValue)")
            let errorMessage = await Self.fetchErrorMessage()
            self = .unknown(errorMessage: errorMessage)
        }
    }

    var errorMessage: String? {
        switch self {
        case .unknown(errorMessage: let errorMessage),
                .stopping(errorMessage: let errorMessage),
                .stopped(errorMessage: let errorMessage):
            return errorMessage
        case .disabled, .invalid, .starting, .running:
            return nil
        }
    }

    private static func fetchErrorMessage() async -> String? {
        guard let error = await NEURLFilterManager.shared.lastDisconnectError else {
            return nil
        }
        
        return error.localizedDescription
    }
}

extension FilterStatus: CustomDebugStringConvertible {
    public var debugDescription: String {
        var status: String
        var message = ""
        switch self {
        case .unknown(errorMessage: let errorMessage):
            status = "unknown"
            message = errorMessage ?? "(empty)"
        case .disabled:
            status = "disabled"
        case .invalid:
            status = "invalid"
        case .stopping(errorMessage: let errorMessage):
            status = "stopping"
            message = errorMessage ?? "(empty)"
        case .stopped(errorMessage: let errorMessage):
            status = "stopped"
            message = errorMessage ?? "(empty)"
        case .starting:
            status = "starting"
        case .running:
            status = "running"
        }

        return "<\(Self.self): '\(status)'\(message.isEmpty ? "" : " errorMessage: '\(message)'")>"
    }
}
