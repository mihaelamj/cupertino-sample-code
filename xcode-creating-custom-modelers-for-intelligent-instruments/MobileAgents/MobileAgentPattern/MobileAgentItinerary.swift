/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Mobile Agent Itinerary holds the planning information of a Mobile Agent to determine its subsequent stops and final stop.
*/

import Foundation
import os.signpost

extension MobileAgent {

    class Itinerary: MockDelayable {
    
        internal var nextStop: MobileAgentStop?
        internal var currentStop: MobileAgentStop?
        internal var finalDestination: MobileAgentStop?
        internal var nextMode: MobileAgent.Mode = .finished
        internal var nextMovementType: MobileAgent.MovementType = .unset {
            didSet { updated = true }
        }
        internal var updated: Bool = false
        internal var mockDelay: useconds_t

        init(movementDelay: useconds_t = 0) {
            self.mockDelay = movementDelay
        }

        private func injectMockDelay() {
            if mockDelay > 0 {
                usleep(mockDelay)
            }
        }

        func setNextStop(to stop: MobileAgentStop?, mode: MobileAgent.Mode) {
            self.nextStop = stop
            self.nextMode = mode
            self.nextMovementType = .normal
        }

        func revisit() {
            self.nextMovementType = .revisit
        }

        func finishedWithMode(mode: MobileAgent.Mode) {
            self.nextStop = nil
            self.nextMode = mode
            self.nextMovementType = .park
        }

        private func prepareAgentForNextStop(agent: MobileAgent) -> MobileAgentStop? {

            let destination = nextStop
            agent.mode = nextMode
            agent.movementType = nextMovementType

            self.currentStop = nextStop
            self.nextMovementType = .unset

            return destination
        }

        private func prepareAgentForParking(agent: MobileAgent) -> MobileAgentStop? {

            let destination = finalDestination
            agent.mode = nextMode
            agent.movementType = .park

            self.nextMode = .finished
            self.nextStop = nil
            self.currentStop = nil
            self.finalDestination = nil

            return destination
        }

        internal func visitNextStop(agent: MobileAgent) {
            // Determine where the next destination is and performs some sanity checks to ensure
            // the MobileAgent is traveling with a valid itinerary.
            let destination: MobileAgentStop?

            switch nextMovementType {
                case .revisit, .normal:
                    destination = prepareAgentForNextStop(agent: agent)
                case .park:
                    destination = prepareAgentForParking(agent: agent)
                case .unset:
                    destination = nil
            }

            self.updated = false

            if let destination = destination {
                let signpostID = OSSignpostID(UInt64(agent.diagnosticsTypeCode()))
                os_signpost(.event,
                            log: MobileAgent.signpostHandle,
                            name: "Mobile Agent Moved",
                            signpostID: signpostID,
                            "Agent of type %d received by %d for mode %@ movement type %d",
                            agent.diagnosticsTypeCode(),
                            destination.diagnosticsTypeCode(),
                            agent.mode.identifier,
                            agent.movementType.rawValue)
                injectMockDelay()
                destination.receiveMobileAgent(agent: agent)
            } else {
                guard agent.movementType == .park else {
                    fatalError("Agent isn't parking, but it doesn't have a stop to go to.")
                }
                agent.goodbye()
            }
        }
    }
}
