/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data that a backyard contains.
*/

import Foundation
import OSLog

private let logger = Logger(subsystem: "Backyard Birds Data", category: "BackyardsData")

final class BackyardsData: ObservableObject {
    @Published var lastSimulationDate: Date?
    @Published var backyards: [Backyard]

    var requiresInitialDataGeneration: Bool {
        lastSimulationDate == nil
    }

    init(lastSimulationDate date: Date? = nil) {
        self.lastSimulationDate = date
        self.backyards = []

        simulateHistoricalEvents()
    }

    private func simulateHistoricalEvents() {
        if requiresInitialDataGeneration {
            logger.info("Requires an initial data generation")
            generateInitialData()
        }
    }

    private func generateInitialData() {
        logger.info("Generating initial data...")

        var random = SeededRandomGenerator(seed: 1)
        let birds = Bird.all(random: &random).shuffled(using: &random)
        let backyards = Backyard.all(random: &random)
        for (bird, backyard) in zip(birds, backyards) {
            let event = BackyardVisitorEvent(backyard: backyard, bird: bird, startDate: .now, duration: 10_000)
            backyard.visitorEvents.append(event)
            backyard.presentingVisitor = true
        }

        logger.info("Done generating initial data.")
        lastSimulationDate = .now
        self.backyards = backyards
    }
}

struct SeededRandomGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }

    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}
