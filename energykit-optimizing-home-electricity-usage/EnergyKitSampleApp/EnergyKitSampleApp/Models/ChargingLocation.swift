/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftData model class of charging locations.
*/

import EnergyKit
import Foundation
import SwiftData
import SwiftUI

@Model final class ChargingLocation {
    var energyVenueName: String
    var energyVenueID: UUID
    var isCECEnabled: Bool

    init(energyVenueName: String, energyVenueID: UUID, isCECEnabled: Bool = false) {
        self.energyVenueName = energyVenueName
        self.energyVenueID = energyVenueID
        self.isCECEnabled = isCECEnabled
    }
}
