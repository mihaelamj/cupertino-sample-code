/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The DisplayStop executes incoming MobileAgents directly by invoking their `hello()` and `goodbye()`
     functions.
*/
import Foundation

class DisplayStop: MobileAgentStop {
    
    func receiveMobileAgent(agent: MobileAgent) {
        dispatchPrecondition(condition: .onQueue(.main))
        agent.hello()
        agent.goodbye()
    }

    func diagnosticsTypeCode() -> UInt32 {
        return 2
    }
    
}
