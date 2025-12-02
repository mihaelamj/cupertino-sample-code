/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data provider that loads flight itinerary data from disk into memory,
 and saves the in-memory data back to disk.
*/

import Combine
import Foundation
import os.log

@MainActor
final class FlightData: ObservableObject {
    let logger = Logger(subsystem: "com.example.apple-samplecode.FlightPlanner.FlightData", category: "Model")
    
    /// The list of flight segments, sorted by departure date.
    @Published var segments: [FlightSegment] = []
    @Published private var itinerary: [FlightSegment.ID: FlightSegment]
    
    init(itinerary: [FlightSegment] = []) {
        self.itinerary = itinerary.indexed()
        $itinerary
            .map { $0.values.sorted() }
            .assign(to: &$segments)
    }
    
    /// An actor that saves and loads the flight data in the background.
    private let store = Store()
    
    /// Synchronously add the flight segment in memory, then asynchronously write to disk.
    func addSegment(_ segment: FlightSegment) {
        itinerary[segment.id] = segment
       
        Task.detached {
            await self.save()
        }
    }
    
    /// Synchronously remove the flight second in memory, then asynchronously delete from disk.
    func removeSegment(_ segment: FlightSegment) {
        itinerary[segment.id] = nil
        
        Task.detached {
            await self.save()
        }
    }
    
    /// Synchronously remove the flight leg for a given offset in memory,
    /// then asynchronously delete from disk.
    func removeLegs(atOffsets offsets: IndexSet, in segment: FlightSegment) {
        guard segment.legs.count > 1 else {
            removeSegment(segment)
            return
        }
        
        var legs = segment.legs
        legs.remove(atOffsets: offsets)
        
        guard let updatedSegment = FlightSegment(id: segment.id, legs: legs)
        else { return }
        
        itinerary[segment.id] = updatedSegment
        
        Task.detached {
            await self.save()
        }
    }
    
    /// Asynchroonously read the flight itinerary data from disk.
    func load() async {
        itinerary = await store.load().indexed()
    }
    
    /// Asynchronously write the flight itinerary data to disk.
    func save() async {
        logger.debug("Updating the system based on the current `segments` property.")
        await store.save(segments)
    }
}

extension FlightData {
    private actor Store {
        let logger = Logger(subsystem: "com.example.apple-samplecode.FlightPlanner.FlightData.Store", category: "ModelIO")
        
        /// Use this value to determine whether you have changes that you can save to disk.
        private var savedItinerary: [FlightSegment] = []
        
        /// Begin loading the data from disk.
        func load() -> [FlightSegment] {
            load(from: .main)
        }
        
        private func load(from bundle: Bundle) -> [FlightSegment] {
            // Read the data from a background queue.
            logger.debug("Loading the data from disk.")
            
            var itinerary: [FlightSegment]
            do {
                // Load the flight itinerary data from a binary JSON file.
                let data = try Data(contentsOf: dataURL, options: .mappedIfSafe)
                // Decode the data as flight segments.
                let decoder = JSONDecoder()
                let segmentType = [FlightSegment].self
                let segments = try decoder.decode(segmentType, from: data)
                // Then sort the flight segments.
                itinerary = segments.sorted()
            } catch CocoaError.fileReadNoSuchFile {
                logger.debug("No file found -- creating an empty flight itinerary list.")
                itinerary = []
            } catch {
                logger.error("*** An error occurred while loading the flight data: \(error.localizedDescription) ***")
                fatalError()
            }
            
            // Store the loaded flight data in memory to track changes.
            savedItinerary = itinerary
            
            return itinerary
        }
        
        // Begin saving the flight data to disk.
        func save(_ itinerary: [FlightSegment]) {
            
            // Don't save the data if there aren't any changes.
            if itinerary == savedItinerary {
                logger.debug("The flight itinerary data hasn't changed. No need to save.")
                return
            }
            
            let data: Data
            do {
                // Encode the unsaved changes array.
                data = try JSONEncoder().encode(itinerary)
            } catch {
                logger.error("An error occurred while encoding the flight itinerary data: \(error.localizedDescription)")
                return
            }
            
            // Save the data to disk as a JSON file.
            do {
                // Write the data to disk.
                logger.debug("Asynchronously saving the flight itinerary data on a background thread.")
                try data.write(to: dataURL, options: [.atomic])
                
                // Update the saved value.
                self.savedItinerary = itinerary
                
                self.logger.debug("Flight itinerary data saved!")
            } catch {
                self.logger.error("An error occurred while saving the flight itinerary data: \(error.localizedDescription)")
            }
        }
        
        // Provide the URL for the JSON file that stores the airport data.
        private var dataURL: URL {
            get throws {
                try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                // Append the filename to the directory.
                .appendingPathComponent("Flights.json")
            }
        }
    }
}

extension Sequence where Element: Identifiable {
    /// Creates a new dictionary from the key-value pairs in the given sequence of elements, conforming to
    /// `Identifiable`. The keys are the elements' identifiers and the values are the elements.
    fileprivate func indexed() -> [Element.ID: Element] {
        Dictionary(uniqueKeysWithValues: self.lazy.map { ($0.id, $0) })
    }
}
