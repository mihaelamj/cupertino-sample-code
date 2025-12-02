/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Options for the generation of data.
*/

import Foundation

public class DataGenerationOptions {
    /// The inital birds don't show the new bird indicator card.
    public static let showNewBirdIndicatorCard = false
    
    /// Set the first backyard to not be low on water.
    public static let firstBackyardLowOnWater = false
    
    /// The status of the initial birds is already visible.
    public static let firstBackyardBirdStatus = FirstBackyardBirdStatus.alreadyVisible
    
    /// The initial birds default to visiting for an hour after launch.
    public static let currentBirdsVisitingDuration = TimeInterval(hours: 1)
    
    /// When true, this doesn't save data to disk. When false, it saves data to disk.
    public static let inMemoryPersistence = true
    
    /// Show the "Get Backyard Birds Pass" button in the BackyardGrid, and so on.
    public static let includeBirdPassButton = false

    public static let initialOwnedBirdFoods: [String: Int] = [
        "Nutrition Pellet": 3
    ]
}

// MARK: - FirstBackyardBirdStatus

public extension DataGenerationOptions {
    
    enum FirstBackyardBirdStatus {
        /// The bird appears initially as if it's been there for a while.
        case alreadyVisible
        
        /// The bird is visiting, but the system needs to draw it flying in.
        case fliesIn
        
        /// No bird is visiting.
        case notVisiting
    }
}
