/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Configuration represents the various parameters which NEURLFilterManager can be configured with.
 The application of the @Observable macro allows SwiftUI to respond to changes in property values
 and update the user interface appropriately.
*/

import Foundation

@Observable
class Configuration: Codable {
    var enabled: Bool
    var shouldFailClosed: Bool
    var prefilterFetchInterval: TimeInterval
    var controlProviderBundleIdentifier: String?
    var pirServerURL: URL?
    var pirPrivacyPassIssuerURL: URL?
    var pirAuthenticationToken: String?

    init(
        enabled: Bool,
        shouldFailClosed: Bool,
        prefilterFetchInterval: TimeInterval,
        controlProviderBundleIdentifier: String?,
        pirServerURL: URL?,
        pirPrivacyPassIssuerURL: URL?,
        pirAuthenticationToken: String?
    ) {
        self.enabled = enabled
        self.shouldFailClosed = shouldFailClosed
        self.prefilterFetchInterval = prefilterFetchInterval
        self.controlProviderBundleIdentifier = controlProviderBundleIdentifier
        self.pirServerURL = pirServerURL
        self.pirPrivacyPassIssuerURL = pirPrivacyPassIssuerURL
        self.pirAuthenticationToken = pirAuthenticationToken
    }

    // Evaluates the configuration for (non-exhaustive) validity.
    var valid: Bool {
        guard pirServerURL != nil,
              let controlProviderBundleIdentifier,
              !controlProviderBundleIdentifier.isEmpty,
              let pirAuthenticationToken,
              !pirAuthenticationToken.isEmpty else {
            return false
        }
        return true
    }
}

extension Configuration {
    // Default to the minimum refresh frequency of 45 minutes.
    static let minPrefetchFetchFrequency: TimeInterval = 60 * 45
}

extension Configuration: Hashable {
    static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        // Omitting 'enabled' from the hash as this transitory state should not affect equality.
        hasher.combine(shouldFailClosed)
        hasher.combine(prefilterFetchInterval)
        hasher.combine(controlProviderBundleIdentifier)
        hasher.combine(pirServerURL)
        hasher.combine(pirPrivacyPassIssuerURL)
        hasher.combine(pirAuthenticationToken)
    }
}

extension Configuration: CustomDebugStringConvertible {
    var debugDescription: String {
        "<\(Self.self): pirServerURL: '\(pirServerURL?.absoluteString ?? "nil")' pirAuthenticationToken: '\(pirAuthenticationToken ?? "nil")' pirPrivacyPassIssuerURL: '\(pirPrivacyPassIssuerURL?.absoluteString ?? "nil")' enabled: '\(enabled)' shouldFailClosed: '\(shouldFailClosed)' controlProviderBundleIdentifier: '\(controlProviderBundleIdentifier ?? "nil")' prefilterFetchInterval: '\(prefilterFetchInterval)'>"
    }
}
