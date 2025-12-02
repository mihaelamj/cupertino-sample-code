/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MobileAgent is an object which completes a desired goal by breaking the goal up into components which are executed at Mobile Agent Stops.
*/

import Foundation
import os.signpost

// Defines the core functionality of a MobileAgent and provides the appropriate instrumentation for beginning execution as well as parking.

class MobileAgent: MockDelayable, DiagnosticCodeExpressable {
    
    static internal var signpostHandle = OSLog(subsystem: "com.apple.dt.utilities",
                                                category: "Mobile Agent")
    public internal(set) var itinerary: Itinerary
    public internal(set) var mode = Mode.finished
    public internal(set) var movementType = MovementType.unset
    var mockDelay: useconds_t

    init(agentDelay: useconds_t = 0, movementDelay: useconds_t = 0) {
        self.mockDelay = agentDelay
        self.itinerary = Itinerary(movementDelay: movementDelay)
    }
    
    func activateAtStop(stop: MobileAgentStop?, finalDestination: MobileAgentStop?) {
        // Initial activation stage for a MobileAgent.
        itinerary.finalDestination = finalDestination
        itinerary.setNextStop(to: stop, mode: .activating)
        goodbye()
     
    }
    
    private func park() {
        // Invoked when a MobileAgent finishes its journey.
        let signpostID = OSSignpostID(UInt64(self.diagnosticsTypeCode()))
        os_signpost(.event,
                    log: MobileAgent.signpostHandle,
                    name: "Mobile Agent Parked",
                    signpostID: signpostID,
                    "Parked in mode %@",
                    mode.identifier)
        movementType = .unset
    }
    
    func executeStopOnItinerary(itinerary: MobileAgent.Itinerary) {
        // This function is expected to be overridden by subclasses. Once the subclasses
        // have finished processing the `mode` variable, they should invoke super.executeStopOnItinerary()
        // to handle these base cases.
        switch mode {
        case .activating:
            break // Nothing to do
        case .failed, .finished:
            itinerary.finishedWithMode(mode: mode)
        default:
            break // Custom modes handled by subclasses
        }
    }
    
    func diagnosticsTypeCode() -> UInt32 {
        return 0
    }
    
    func deactivated() {
        
    }
    
    func hello() {
        // Instructs the agent to begin executing.
        switch movementType {
        case .revisit, .normal:
            let signpostID = OSSignpostID(UInt64(self.diagnosticsTypeCode()))
            let stop = itinerary.currentStop!
            os_signpost(.event,
                        log: MobileAgent.signpostHandle,
                        name: "Mobile Agent Exec",
                        signpostID: signpostID,
                        "Agent of type %d executing mode %@.  Movement type is %d. At stop %d",
                        self.diagnosticsTypeCode(), mode.identifier, movementType.rawValue, stop.diagnosticsTypeCode())
            injectMockDelay()
            executeStopOnItinerary(itinerary: itinerary)
        case .park:
            break
        case .unset:
            fatalError("Unable to execute at MobileAgentStop - movemenet type is .unset")
        }
    }
    
    func goodbye() {
        // Instructs the agent to consult its itinerary for where to go next.
        if movementType == .park {
            deactivated()
            park()
        } else {
            itinerary.visitNextStop(agent: self)
        }
    }
    
}
