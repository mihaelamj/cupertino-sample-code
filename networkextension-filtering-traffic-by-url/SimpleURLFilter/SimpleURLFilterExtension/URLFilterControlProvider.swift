/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
URLFilterControlProvider implements the NEURLFilterControlProvider protocol to provide
 pre-filter data to the system, and allow for proper handling of start and stop events.
*/

import NetworkExtension
import OSLog

@main
class URLFilterControlProvider: NEURLFilterControlProvider {

    let filterPlistFileName = "bloom_filter"

    private let log = Logger.createLogger(for: URLFilterControlProvider.self)

    required init() {
    }

    func start() async throws {
        log.debug("start")
    }

    func stop(reason: NEProviderStopReason) async throws {
        var message: String
        switch reason {
        case .none:
            message = "No specific reason."
        case .userInitiated:
            message = "The user stopped the provider."
        case .providerFailed:
            message = "The provider failed."
        case .noNetworkAvailable:
            message = "There is no network connectivity."
        case .unrecoverableNetworkChange:
            message = "The device attached to a new network."
        case .providerDisabled:
            message = "The provider was disabled."
        case .authenticationCanceled:
            message = "The authentication process was cancelled."
        case .configurationFailed:
            message = "The provider could not be configured."
        case .idleTimeout:
            message = "The provider was idle for too long."
        case .configurationDisabled:
            message = "The associated configuration was disabled."
        case .configurationRemoved:
            message = "The associated configuration was deleted."
        case .superceded:
            message = "A high-priority configuration was started."
        case .userLogout:
            message = "The user logged out."
        case .userSwitch:
            message = "The active user changed."
        case .connectionFailed:
            message = "Failed to establish connection."
        case .sleep:
            message = "The device went to sleep and disconnectOnSleep is enabled in the configuration."
        case .appUpdate:
            message = "The NEProvider is being updated."
        case .internalError:
            message = "An internal error occurred in the NetworkExtension framework."
        @unknown default:
            message = "Unknown reason."
        }
        log.debug("stop: \(message)")
    }

    func fetchPrefilter() async throws -> NEURLFilterPrefilter? {
        guard let filePath = Bundle.main.path(forResource: filterPlistFileName, ofType: "plist") else {
            log.debug("Plist file '\(self.filterPlistFileName)' not found in the bundle.")
            return nil
        }
        guard let dict = NSDictionary(contentsOfFile: filePath) else {
            log.debug("Failed to load plist as NSDictionary")
            return nil
        }

        log.debug("Config Dictionary: \(dict)")

        let numberOfItems = dict["numberOfItems"] as? Int ?? 0
        let falsePositiveTolerance = dict["falsePositiveTolerance"] as? Double ?? 0
        let numberOfBytes = dict["numberOfBytes"] as? Int ?? 0

        log.debug("numberOfItems \(numberOfItems) falsePositiveTolerance \(falsePositiveTolerance) numberOfBytes \(numberOfBytes)")

        let numberOfBits = dict["numberOfBits"] as? Int ?? 0
        let numberOfHashes = dict["numberOfHashes"] as? Int ?? 0
        let murmurSeed = dict["murmurSeed"] as? Int ?? 0

        let bitVectorData = dict["bitVectorData"] as? Data

        log.debug("bitVectorData bytes \(bitVectorData?.count ?? 0) numberOfBits \(numberOfBits) numberOfHashes \(numberOfHashes) murmurSeed \(murmurSeed)")

        // Save the data into a temporary file and pass it back to host, rather than pass it in-memory.
        let tmpdir = FileManager.default.temporaryDirectory
        let fileURL = tmpdir.appendingPathComponent("bloomfilterdata")

        do {
            try bitVectorData?.write(to: fileURL)
            let prefilterData: NEURLFilterPrefilter.PrefilterData = .temporaryFilepath(fileURL)
            let preFilter = NEURLFilterPrefilter(
                data: prefilterData,
                bitCount: numberOfBits,
                hashCount: numberOfHashes,
                murmurSeed: UInt32(murmurSeed))
            return preFilter
        } catch {
            log.error("Unable to write bit vector data to temp file '\(fileURL)'. Error: \(error)")
            return nil
        }
    }
}
