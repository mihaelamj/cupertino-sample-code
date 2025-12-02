/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SortAgent is responsible for sorting a list of goats that will eventually populate the table view UI.
*/
import Foundation

/*
 The SortAgent operates by following three steps:
     1) Obtaining the list from a central store.
     2) Sorting the list.
     3) Comitting the sorted list back to a central store.
*/

fileprivate extension MobileAgent.Mode {
    static let sortingAgentSortingList = Self.sortGoatList
    static let sortingAgentCommitingList = Self.commitGoatList
    static let sortingAgentRetrievingList = Self.retrieveGoatList
}

class SortAgent: MobileAgent, GoatListReceivable {
    
    var goatList = [Goat]()
    var sortedList = [Goat]()
    
    var goatListStop: GoatListStop
    
    init(goatListStop: GoatListStop) {
        self.goatListStop = goatListStop
        super.init(agentDelay: 200_000, movementDelay: 50_000)
    }
    
    override func diagnosticsTypeCode() -> UInt32 {
        return 1
    }
    
    override func executeStopOnItinerary(itinerary: MobileAgent.Itinerary) {
        switch mode {
        case .activating:
            // Grab the list to sort from the goatListStop
            itinerary.setNextStop(to: goatListStop, mode: .sortingAgentRetrievingList)
        case .retrieveGoatList:
            let sortingStop = BackgroundProcessingStop()
            itinerary.setNextStop(to: sortingStop, mode: .sortingAgentSortingList)
        case .sortGoatList:
            // Sort the list
            self.sortedList = self.goatList.sorted {
                return $0.name < $1.name
            }
            itinerary.setNextStop(to: goatListStop, mode: .sortingAgentCommitingList)
        case .commitGoatList:
            // Commit the sorted list

            goatListStop.populateGoatList(goats: sortedList)

            itinerary.finishedWithMode(mode: .finished)
        default:
            super.executeStopOnItinerary(itinerary: itinerary)
        }
    }
    
}
