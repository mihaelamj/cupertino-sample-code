/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The EditAgent is responsible for editing a list of elements that will eventually be rendered back on the table view UI.
*/

import Foundation
import UIKit

/*
    EditAgent operates by following three steps:
        1) Obtain the list from a central store.
        2) Perform the desired edits.
        3) Commit the edited list back to the central store.

 */

fileprivate extension MobileAgent.Mode {
    static let editingAgentAddingGoat = Self.addGoat
    static let editingAgentCommitingList = Self.commitGoatList
    static let editingAgentRetrievingList = Self.retrieveGoatList
}
 
 class EditAgent: MobileAgent, GoatListReceivable {

    var goatList = [Goat]()
    var goatListStop: GoatListStop
    
    init(goatListStop: GoatListStop) {
        self.goatListStop = goatListStop
        super.init(agentDelay: 200_000, movementDelay: 50_000)
    }

    override func diagnosticsTypeCode() -> UInt32 {
        return 3
    }
    
    override func executeStopOnItinerary(itinerary: MobileAgent.Itinerary) {
        switch mode {
        case .activating:
            itinerary.setNextStop(to: goatListStop, mode: .editingAgentRetrievingList)
        case .retrieveGoatList:
            let editStop = BackgroundProcessingStop()
            itinerary.setNextStop(to: editStop, mode: .editingAgentAddingGoat)
        case .addGoat:
            guard let newGoat = Goat(name: GoatNames.generateGoatName()) else {
                fatalError("Unable to add new user Goat")
            }

            self.goatList.append(newGoat)
            let editStop = BackgroundProcessingStop()
            itinerary.setNextStop(to: editStop, mode: .editingAgentCommitingList)
        case .commitGoatList:
            goatListStop.populateGoatList(goats: goatList)
            itinerary.finishedWithMode(mode: .finished)
        default:
            super.executeStopOnItinerary(itinerary: itinerary)
        }
    }
}
