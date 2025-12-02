/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BackgroundProcessingStop receives an incoming Mobile Agent by dispatching its logic on a background thread.
*/

import Foundation

// The BackgroundProcessingStop serves as a mechanism for MobileAgents to dispatch Sorting and Editing work onto.
class BackgroundProcessingStop: MobileAgentStop {
    func receiveMobileAgent(agent: MobileAgent) {
        DispatchQueue.global(qos: .userInitiated).sync {
            agent.hello()
            agent.goodbye()
        }
        
    }
    
    func diagnosticsTypeCode() -> UInt32 {
        return 1
    }
   
}
