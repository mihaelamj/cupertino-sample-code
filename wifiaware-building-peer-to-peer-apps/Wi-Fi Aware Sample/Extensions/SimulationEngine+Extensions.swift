/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions to the simulation engine.
*/

import WiFiAware
import Network
import SwiftUI

extension SimulationEngine {
    enum Mode: String, CustomStringConvertible {
        case host = "Host"
        case viewer = "Viewer"

        var description: String {
            self.rawValue
        }
    }

    enum HostState {
        case stopped
        case publishing
    }

    enum ViewerState {
        case stopped
        case browsing
        case connecting
        case connected
    }

    enum NetworkState: Equatable {
        case host(HostState)
        case viewer(ViewerState)

        var description: String {
            switch self {
            case .host(let hostState):
                switch hostState {
                case .stopped: return "Advertise"
                case .publishing: return "Stop Advertising"
                }

            case .viewer(let viewerState):
                switch viewerState {
                case .stopped: return "Discover & Connect"
                case .browsing: return "Discovering"
                case .connecting: return "Connecting"
                case .connected: return "Connected"
                }
            }
        }

        var color: Color {
            switch self {
            case .host(let hostState):
                switch hostState {
                case .stopped: return .white
                case .publishing: return .blue
                }

            case .viewer(let viewerState):
                switch viewerState {
                case .stopped: return .white
                case .browsing: return .blue
                case .connecting: return .green
                case .connected: return .clear
                }
            }
        }
    }
}
