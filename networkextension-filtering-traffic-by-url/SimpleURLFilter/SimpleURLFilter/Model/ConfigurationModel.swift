/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ConfigurationModel is the main interface with the NEURLFilterManager API for this application.
 The model class instance holds a reference to the current configuration and filter status, and
 can be used to interface with the underlying system to perform various actions and be informed
 of changes to the filter by the system.
*/

import Foundation
import NetworkExtension
import OSLog

@MainActor
@Observable
class ConfigurationModel {
    var currentConfiguration: Configuration?
    var filterStatus: FilterStatus

    private let sharedFilterManager = NEURLFilterManager.shared
    private let log = Logger.createLogger(for: ConfigurationModel.self)

    public init() {
        filterStatus = .unknown(errorMessage: nil)
        // Start listening for status and configuration updates.
        initiateStatusUpdate()
        initiateConfigurationUpdate()
    }

    public func loadCurrentConfiguration() async throws {
        // Load the configuration into the manager, and export it as our Configuration object.
        try await sharedFilterManager.loadFromPreferences()
        let configuration = exportConfiguration()
        currentConfiguration = configuration
        log.debug("Loaded current configuration: \(configuration.debugDescription)")
    }

    public func save(configuration: Configuration) async throws {
        guard let pirServerURL = configuration.pirServerURL, let pirAuthenticationToken = configuration.pirAuthenticationToken else {
            throw ConfigurationError.badConfiguration
        }

        // Set `controlProviderBundleIdentifier` to a default value, if needed.
        let controlProviderBundleIdentifier = defaultControlProviderBundleIdentifier(given: configuration.controlProviderBundleIdentifier)
        log.debug("Save Configuration: \(configuration.debugDescription) (using controlProviderBundleIdentifier '\(controlProviderBundleIdentifier)')")

        // Set the configuration on the manager; staging it to be saved.
        try sharedFilterManager.setConfiguration(pirServerURL: pirServerURL,
                                                 pirPrivacyPassIssuerURL: configuration.pirPrivacyPassIssuerURL,
                                                 pirAuthenticationToken: pirAuthenticationToken,
                                                 controlProviderBundleIdentifier: controlProviderBundleIdentifier)

        sharedFilterManager.prefilterFetchInterval = configuration.prefilterFetchInterval
        sharedFilterManager.shouldFailClosed = configuration.shouldFailClosed
        sharedFilterManager.isEnabled = configuration.enabled

        do {
            // Save the configuration.
            try await sharedFilterManager.saveToPreferences()
            currentConfiguration = configuration
            log.debug("Saved configuration.")
        } catch NEURLFilterManager.Error.configurationUnchanged {
            // No need to report this as an error to the user, so just log it.
            log.debug("Configuration unchanged.")
        }
    }

    public func removeCurrentConfiguration() async throws {
        log.debug("Removing configuration.")
        try await sharedFilterManager.removeFromPreferences()
        log.debug("Removed configuration.")
        // Load the configuration from preferences, and fetch status, to maintain parity with the system.
        // (no configuration update via `handleConfigChange()` is sent due to calling `removeFromPreferences()`)
        log.debug("Reloading configuration.")
        try await refreshFromSystem()
        log.debug("Configuration removal complete.")
    }

    public func currentConfiguration(enable: Bool) async throws {
        sharedFilterManager.isEnabled = enable
        try await sharedFilterManager.saveToPreferences()
        currentConfiguration = exportConfiguration()
    }

    public func resetPIRCache() async throws {
        log.debug("Resetting PIR cache.")
        try await sharedFilterManager.resetPIRCache()
        log.debug("PIR cache reset.")
    }

    public func refreshPIRParameters() async throws {
        log.debug("Refreshing PIR parameters.")
        try await sharedFilterManager.refreshPIRParameters()
        log.debug("PIR parameters refreshed.")
    }

    public func status() async -> FilterStatus {
        let status = await sharedFilterManager.status
        let filterStatus = await FilterStatus(status: status, configuration: currentConfiguration)
        return filterStatus
    }

    func refreshFromSystem() async throws {
        // Refresh state from system.
        try await loadCurrentConfiguration()
        let updatedStatus = await status()
        filterStatus = updatedStatus
    }

    private func initiateConfigurationUpdate() {
        Task {
            for await _ in sharedFilterManager.handleConfigChange() {
                log.debug("Reveived configuration change notification.")
                do {
                    try await loadCurrentConfiguration()
                    log.debug("Reveived updated configuration: \(self.currentConfiguration?.debugDescription ?? "")")
                } catch {
                    log.error("Failed to load updated configuration: \(error)")
                }
            }
        }
    }

    private func initiateStatusUpdate() {
        Task {
            for await status in sharedFilterManager.handleStatusChange() {
                let updatedStatus = await FilterStatus(status: status, configuration: currentConfiguration)
                log.debug("Received filter status change: \(String(describing: updatedStatus))")
                filterStatus = updatedStatus
            }
        }
    }

    private func exportConfiguration() -> Configuration {
        Configuration(
            enabled: sharedFilterManager.isEnabled,
            shouldFailClosed: sharedFilterManager.shouldFailClosed,
            prefilterFetchInterval: sharedFilterManager.prefilterFetchInterval,
            controlProviderBundleIdentifier: sharedFilterManager.controlProviderBundleIdentifier,
            pirServerURL: sharedFilterManager.pirServerURL,
            pirPrivacyPassIssuerURL: sharedFilterManager.pirPrivacyPassIssuerURL,
            pirAuthenticationToken: sharedFilterManager.pirAuthenticationToken)
    }

    private func defaultControlProviderBundleIdentifier(given id: String?) -> String {
        // Use the given control provider bundle identifier, if supplied, otherwise inspect
        // the main Bundle for a matching network filter extension bundle.
        // NOTE: This identifier must match your network extension's bundle identifier.
        guard let id, !id.isEmpty else {
            return Bundle.findURLFilterControlNetworkExtensionBundleID() ?? ""
        }

        return id
    }

}

extension ConfigurationModel {
    public enum ConfigurationError: Error {
        case badConfiguration
    }
}
