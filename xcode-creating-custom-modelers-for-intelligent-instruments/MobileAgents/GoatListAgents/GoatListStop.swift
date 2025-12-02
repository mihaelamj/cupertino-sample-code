/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The GoatListStop serves as a central store for the most up-to-date list that should be rendered on the UI.
*/

import Foundation

/*
 Mobile Agents that visit this stop can obtain or set the list.
*/
class GoatListStop: MobileAgentStop {

    private var goatList = [Goat]()
    
    func populateGoatList(goats: [Goat]) {
        goatList = goats
    }
    func receiveMobileAgent(agent: MobileAgent) {
        dispatchPrecondition(condition: .onQueue(.main))
        
        if var goatListReceiver = agent as? GoatListReceivable {
            goatListReceiver.goatList = goatList
        }
        agent.hello()
        agent.goodbye()
    }
    
    func diagnosticsTypeCode() -> UInt32 {
        return 4
    }
}
