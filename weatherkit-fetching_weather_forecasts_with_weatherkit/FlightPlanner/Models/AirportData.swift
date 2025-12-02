/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data provider that loads airport data from disk into memory.
*/

import Foundation
import os.log

@MainActor
class AirportData: ObservableObject {
    let logger = Logger(subsystem: "com.example.apple-samplecode.FlightPlanner.AirportData", category: "Model")
    
    /// The list of airports.
    @Published private(set) var airports: [Airport]
    
    init(airports: [Airport] = []) {
        self.airports = airports
    }
    
    private let store = Store()
    
    /// Asynchronously read the airport data from disk.
    func load() async {
        airports = await store.load()
    }
}

extension AirportData {
    private actor Store {
        let logger = Logger(subsystem: "com.example.apple-samplecode.FlightPlanner.AirportData.Store", category: "ModelIO")
        
        func load() -> [Airport] {
            load(from: .main)
        }
        
        private func load(from bundle: Bundle) -> [Airport] {
            // Read the data from a background queue.
            logger.debug("Loading the data from disk.")
            
            var airports: [Airport]
            do {
                // Load the airport data from a binary JSON file.
                let data = try Data(contentsOf: Store.dataURL, options: .mappedIfSafe)
                // Decode the data.
                airports = try JSONDecoder().decode([Airport].self, from: data)
            } catch CocoaError.fileReadNoSuchFile {
                logger.debug("No file found -- creating an empty airport list.")
                airports = []
            } catch {
                logger.error("*** An error occurred while loading the airport list: \(error.localizedDescription) ***")
                fatalError()
            }
            return airports
        }
        
        // Provide the URL for the JSON file that stores the airport data.
        fileprivate static var dataURL: URL {
            get throws {
                let bundle = Bundle.main
                guard let path = bundle.path(forResource: "Airports", ofType: "json") else {
                    throw CocoaError(.fileReadNoSuchFile)
                }
                return URL(fileURLWithPath: path)
            }
        }
    }
}
