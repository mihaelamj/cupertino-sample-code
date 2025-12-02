/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The DisplayAgent updates the table view UI with the most updated list of goats.
*/

import Foundation
import UIKit

/*
 A DisplayAgent breaks down the goal of updating the UI list into two steps:
     1) Obtain the list from a central store.
     2) Use that list as the list of items that will be rendered on the sample app's table view.
*/

fileprivate extension MobileAgent.Mode {
    static let displayingAgentRetrievingList = Self.retrieveGoatList
    static let displayingAgentDisplayingList = Self.displayGoatList
}

class DisplayAgent: MobileAgent, GoatListReceivable {
    
    var goatTableViewController: GoatTableViewController
    var goatList = [Goat]()
    var goatListStop: GoatListStop
    
    init(goatListStop: GoatListStop, goatTableViewController: GoatTableViewController) {
        self.goatListStop = goatListStop
        self.goatTableViewController = goatTableViewController
        super.init(agentDelay: 200_000, movementDelay: 50_000)
    }
    
    override func diagnosticsTypeCode() -> UInt32 {
        return 2
    }
    
    override func executeStopOnItinerary(itinerary: MobileAgent.Itinerary) {
        switch mode {
        case .activating:
            itinerary.setNextStop(to: goatListStop, mode: .displayingAgentRetrievingList)
        case .displayingAgentRetrievingList:
            // Retrieve the list
            let displayStop = DisplayStop()
            itinerary.setNextStop(to: displayStop, mode: .displayingAgentDisplayingList)
        case .displayingAgentDisplayingList:
            // Update the UI
            goatTableViewController.goatList = self.goatList
            goatTableViewController.tableView.reloadData()
            itinerary.finishedWithMode(mode: .finished)
        default:
            super.executeStopOnItinerary(itinerary: itinerary)
        }
    }
    
}
