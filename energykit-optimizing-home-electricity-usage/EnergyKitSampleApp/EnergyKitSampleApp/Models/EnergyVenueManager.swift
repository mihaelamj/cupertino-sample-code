/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An observable class that encapsulates EnergyKit's guidance and insights operations.
*/

import BackgroundTasks
import EnergyKit
import Foundation
import OSLog

/// An observable class that encapsulates EnergyKit's guidance and insights operations.
@Observable final class EnergyVenueManager {
    /// The active guidance.
    var guidance: ElectricityGuidance?

    /// The task used to stream guidance.
    private var streamGuidanceTask: Task<(), Error>?
    
    /// The venue for the device.
    let venue: EnergyVenue

    init?(venueID: UUID) async {
        guard let energyVenue = try? await EnergyVenue.venue(for: venueID) else {
            return nil
        }
        venue = energyVenue
    }

    /// Stream guidance for the venue.
    fileprivate func streamGuidance(
        venueID: UUID,
        update: (_ guidance: ElectricityGuidance) -> Void
    ) async throws {
        let query = ElectricityGuidance.Query(suggestedAction: .shift)
        for try await currentGuidance in ElectricityGuidance.sharedService.guidance(
            using: query,
            at: venueID
        ) {
            update(currentGuidance)
        }
    }

    /// Starts streaming guidance and stores the value in the observed `guidance` property.
    func startGuidanceMonitoring() {
        // Cancel the current active task.
        streamGuidanceTask?.cancel()
        streamGuidanceTask = Task.detached { [weak self] in
            if let venueID = self?.venue.id {
                try? await self?.streamGuidance(venueID: venueID) { guidance in
                    self?.guidance = guidance
                    if Task.isCancelled {
                        return
                    }
                }
            }
        }
    }

    fileprivate func createInsightsQuery(on date: Date) -> ElectricityInsightQuery {
        return ElectricityInsightQuery(
            options: .cleanliness.union(.tariff),
            range: DateInterval(start: date, end: Date.now),
            granularity: .daily,
            flowDirection: .imported
        )
    }

    func generateInsights(for vehicleIdentifier: String, on date: Date) async throws -> [ElectricityInsightRecord<Measurement<UnitEnergy>>] {
        let query = createInsightsQuery(on: date)
        var records = [ElectricityInsightRecord<Measurement<UnitEnergy>>]()
        for await record in try await ElectricityInsightService.shared.energyInsights(
            forDeviceID: vehicleIdentifier,
            using: query,
            atVenue: self.venue.id
        ) {
            records.append(record)
        }
        return records
    }
}
