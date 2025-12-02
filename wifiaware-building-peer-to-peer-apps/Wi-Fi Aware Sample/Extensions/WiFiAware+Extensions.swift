/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions to the WiFiAware framework.
*/

import WiFiAware
import Network

let simulationServiceName = "_sat-simulation._udp"

extension WAPublishableService {
    public static var simulationService: WAPublishableService {
        allServices[simulationServiceName]!
    }
}

extension WASubscribableService {
    public static var simulationService: WASubscribableService {
        allServices[simulationServiceName]!
    }
}

extension WAAccessCategory {
    var serviceClass: NWParameters.ServiceClass {
        switch self {
        case .bestEffort: .bestEffort
        case .background: .background
        case .interactiveVideo: .interactiveVideo
        case .interactiveVoice: .interactiveVoice
        default : .bestEffort
        }
    }
}

extension WAPairedDevice {
    var displayName: String {
        let displayName = self.name ?? self.pairingInfo?.pairingName ?? ""
        return "\(displayName) (\(self.pairingInfo?.vendorName ?? ""))"
    }
}

extension WAPerformanceReport {
    var display: String {
        return "[\(self.timestamp)] Signal Strength: \(self.signalStrength?.description ?? "-"), Transmit Latency: \(self.transmitLatency)"
    }
}
