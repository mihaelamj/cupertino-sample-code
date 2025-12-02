/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `Itinerary` is a guided tour of San Francisco, comprised of an array of `ItineraryStop` values,
 representing each stop.
*/

import Foundation
import CoreLocation
@preconcurrency import MapKit

/// The item ID type for map items and Look Around scenes.
struct MapItemID: Hashable {
    var uniqueID: Int
}

/// The item ID type for map routes between two map items.
struct MapRouteID: Hashable {
    var startItemID: MapItemID
    var endItemID: MapItemID
}

/// Configuration information about a stop on the tour, decoded from the `TourStops` plist file.
private struct TourStop: Decodable {
    
    /// The title of the map feature at this stop.
    let title: String
    
    /// The latitude of the map feature.
    let latitude: CLLocationDegrees
    
    /// The longitude of the map feature.
    let longitude: CLLocationDegrees
    
    /// The stop sequence number, used to order the tour.
    let stopNumber: Int
    
    /// The latitude and longitude of the map feature, converted to a `CoreLocation` coordinate object.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// A stop in the tour's itinerary.
struct ItineraryStop: Sendable, Identifiable {
    
    /// The unique identifier of this stop.
    var id: MapItemID { mapItemID }
    
    /// The title of the map feature at this stop.
    let title: String
    
    /// The latitude and longitude of the map feature for this item.
    let coordinate: CLLocationCoordinate2D
    
    /// The ID of the map item for this stop.
    let mapItemID: MapItemID
    
    /// The map item for this stop.
    let mapItem: MKMapItem
}

/// Adds `Hashable` and `Equatable` conformance to `ItineraryStop`.
extension ItineraryStop: Hashable, Equatable {
    
    static func == (lhs: ItineraryStop, rhs: ItineraryStop) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// The tour's itinerary.
@MainActor
class Itinerary {
    
    /// Results of loading objects of type `MKLookAroundScene`.
    private var lookAroundSceneResults = MapDataResults<MapItemID, MKLookAroundScene?>()
    
    /// An array of the stops in the itinerary.
    let stops: [ItineraryStop]
    
    fileprivate typealias ItemConfiguration = (tourStop: TourStop, mapItem: MKMapItem, mapItemID: MapItemID)
    
    /// Initializes a tour itinerary.
    init() async {
        
        // Decode the tour stop configuration data from a resource file.
        let tourStopsURL = Bundle.main.url(forResource: "TourStops", withExtension: "plist")!
        let tourStopsData = try! Data(contentsOf: tourStopsURL)
        let tourStops = try! PropertyListDecoder().decode([TourStop].self, from: tourStopsData)
        
        // Concurrently translate stop configurations into itinerary stops.
        stops = await withTaskGroup(of: ItemConfiguration?.self, returning: [ItineraryStop].self) { group in
            
            // Create a child task for each stop.
            for (index, tourStop) in tourStops.enumerated() {
                group.addTask {
                    
                    // Associate each valid tour configuration with a unique map item ID.
                    do {
                        let mapItemID = MapItemID(uniqueID: index)
                        
                        // Use a small region to ensure the result is the expected map item.
                        let region = MKCoordinateRegion(center: tourStop.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
                        
                        // Create a search request for the feature inside that region.
                        let searchRequest = MKLocalSearch.Request()
                        searchRequest.region = region
                        searchRequest.naturalLanguageQuery = tourStop.title
                        
                        // Try to satisfy the search request.
                        let search = MKLocalSearch(request: searchRequest)
                        do {
                            let searchResult = try await search.start()
                            guard let mapItem = searchResult.mapItems.first else {
                                throw MapDataError.mapSearchFailed(mapItemID, tourStop.title)
                            }
                            return (tourStop, mapItem, mapItemID)
                        }
                        
                        // Or report the error.
                        catch {
                            throw MapDataError.mapSearchError(mapItemID, tourStop.title, error)
                        }
                    } catch let error {
                        debugPrint(error)
                        return nil
                    }
                }
            }
            
            // Collect all of the non-`nil` child task results, sorted, as an array of itinerary stops.
            var items = await group.reduce(into: [] as [ItemConfiguration]) {
                if let item = $1 {
                    $0.append(item)
                }
            }
            items.sort {
                $0.tourStop.stopNumber < $1.tourStop.stopNumber
            }
            let itineraryStops = items.map { (tourStop, mapItem, mapItemID) in
                ItineraryStop(title: tourStop.title, coordinate: tourStop.coordinate, mapItemID: mapItemID, mapItem: mapItem)
            }
            
            return itineraryStops
        }
    }
    
    /// Gets the `MKLookAroundScene` for a map item after loading it asynchronously if necessary.
    /// - parameter mapItemID: The item ID of the map item.
    /// - returns: The Look Around scene, or throws an error if loading failed.
    func lookAroundScene(for mapItemID: MapItemID) async throws -> MKLookAroundScene? {
        let mapItem = stops.first { $0.mapItemID == mapItemID }!.mapItem
        let sceneResult: Result<MKLookAroundScene?, Error>
        
        // If the scene already loaded, get the stored result.
        if let result = lookAroundSceneResults.availableResult(for: mapItemID) {
            sceneResult = result
        }
        
        // Otherwise, start a loading `Task` if necessary, and wait for the result.
        else {
            sceneResult = await lookAroundSceneResults.result(for: mapItemID) {
                
                let sceneRequest = MKLookAroundSceneRequest(mapItem: mapItem)
                do {
                    // If fetching the `MKLookAroundScene` returns `nil` without an `Error`,
                    // Look Around is unavailable for that location.
                    return try await sceneRequest.scene
                } catch {
                    throw MapDataError.sceneRequestError(mapItemID, mapItem.placemark.title, error)
                }
            }
        }
        
        return try sceneResult.get()
    }
}
