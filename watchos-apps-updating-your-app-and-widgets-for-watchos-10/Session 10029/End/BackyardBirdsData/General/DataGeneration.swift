/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The generation data.
*/

import Observation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "BackyardBirdsData", category: "DataGeneration")

// MARK: - Data generation

@Model public final class DataGeneration {
    public var lastSimulationDate: Date?
    
    @Transient public var requiresInitialDataGeneration: Bool {
        lastSimulationDate == nil
    }
    
    public init(lastSimulationDate date: Date?) {
        self.lastSimulationDate = date
    }
    
    private func simulateHistoricalEvents(modelContext: ModelContext) {
        logger.info("Attempting to simulate historical events...")
        if requiresInitialDataGeneration {
            logger.info("Requires an initial data generation")
            generateInitialData(modelContext: modelContext)
        }
        
        logger.info("Generating history since last simulation")
        lastSimulationDate = .now
    }
    
    private func generateInitialData(modelContext: ModelContext) {
        logger.info("Generating initial data...")
        
        // First, generate all available bird food, bird species, and plant species.
        logger.info("Generating all bird foods")
        BirdFood.generateAll(modelContext: modelContext)
        logger.info("Generating all bird species")
        BirdSpecies.generateAll(modelContext: modelContext)
        logger.info("Generating plant species")
        PlantSpecies.generateAll(modelContext: modelContext)
        
        // Then, generate instances of individual plants not tied to any backyards, all of the birds,
        // and the backyards themselves (with their own plants).
        logger.info("Generating initial instances of individual plants")
        Plant.generateIndividualPlants(modelContext: modelContext)
        logger.info("Generating initial instances of all birds")
        Bird.generateAll(modelContext: modelContext)
        logger.info("Generating initial instances of backyards")
        Backyard.generateAll(modelContext: modelContext)
        
        // Now that you've generated everything, it's time to make the historical and future events.
        logger.info("Generating visitor events")
        BackyardVisitorEvent.generateHistoricalEvents(modelContext: modelContext)
        BackyardVisitorEvent.generateCurrentEvents(modelContext: modelContext)
        BackyardVisitorEvent.generateFutureEvents(modelContext: modelContext)
        
        logger.info("Generating account")
        // The app content is complete, so now you can create the user's account.
        Account.generateAccount(modelContext: modelContext)
        
        logger.info("Completed generating initial data")
        lastSimulationDate = .now
    }
    
    public static func generateAllData(modelContext: ModelContext) {
        let instance: DataGeneration
        if let result = try! modelContext.fetch(FetchDescriptor<DataGeneration>()).first {
            instance = result
        } else {
            instance = DataGeneration(lastSimulationDate: nil)
            modelContext.insert(instance)
        }
        logger.info("Attempting to statically simulate historical events...")
        instance.simulateHistoricalEvents(modelContext: modelContext)
    }
}

public extension DataGeneration {
    static let container = try! ModelContainer(for: schema, configurations: [.init(inMemory: DataGenerationOptions.inMemoryPersistence)])
    
    static let schema = SwiftData.Schema([
        DataGeneration.self,
        Account.self,
        PlantSpecies.self,
        Plant.self,
        BirdSpecies.self,
        BirdFood.self,
        Bird.self,
        Backyard.self,
        BackyardVisitorEvent.self
    ])
}
