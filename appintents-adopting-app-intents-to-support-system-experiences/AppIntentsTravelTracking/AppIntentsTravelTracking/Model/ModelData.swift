/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The object that manages the app's data.
*/

import Foundation
import MapKit
import CoreLocation

@Observable @MainActor
class ModelData {
    var landmarks: [Landmark] = []
    var landmarksByContinent: [Continent: [Landmark]] = [:]
    var featuredLandmark: Landmark?
    var landmarkOccupancy = [Landmark.ID: Int]()

    var favoritesCollection: Collection!
    var userCollections: [Collection] = []
    var recentlyDeletedCollections: [Int: Collection] = [:]

    var landmarksById: [Int: Landmark] = [:]
    var mapItemsByLandmarkId: [Int: MKMapItem] = [:]
    var mapItemsForLandmarks: [MKMapItem] {
        guard let mapItems = mapItemsByLandmarkId.values.map(\.self) as? [MKMapItem] else {
            return []
        }
        return mapItems
    }

    var searchTerm: String = "" {
        didSet {
            self.filterLandmarks(term: searchTerm, tokens: searchTokens)
        }
    }
    var searchTokens: [SearchToken] = [] {
        didSet {
            self.filterLandmarks(term: searchTerm, tokens: searchTokens)
        }
    }

    var locationFinder: LocationFinder?
    
    init() {
        loadLandmarks()
        loadCollections()
        setOccupancy()

        Task {
            do {
                let fetched = try await fetchMapItems(for: landmarks)
                
                await MainActor.run {
                    self.mapItemsByLandmarkId = fetched
                }
            } catch {
                print("Couldn't fetch map items: \(error.localizedDescription)")
            }
        }
    }
    
    func loadLandmarks() {
        landmarks = Landmark.exampleData
        landmarksByContinent = landmarksByContinent(from: landmarks)
        
        for landmark in landmarks {
            landmarksById[landmark.id] = landmark
        }

        if let mountFuji = landmarksById[1016] {
            featuredLandmark = mountFuji
        }
    }

    func setOccupancy() {
        for landmark in landmarks {
            landmarkOccupancy[landmark.id] = Int.random(in: 0...100)
        }

        landmarkOccupancy[1005] = 76
    }

    func isFavorite(_ landmark: Landmark) -> Bool {
        var isFavorite: Bool = false
        
        if favoritesCollection.landmarks.firstIndex(of: landmark) != nil {
            isFavorite = true
        }
        
        return isFavorite
    }
    
    func addFavorite(_ landmark: Landmark) {
        favoritesCollection.landmarks.append(landmark)
    }

    func removeFavorite(_ landmark: Landmark) {
        if let landmarkIndex = favoritesCollection.landmarks.firstIndex(of: landmark) {
            favoritesCollection.landmarks.remove(at: landmarkIndex)
        }
    }

    func loadCollections() {
        let collectionList: [Collection] = Collection.exampleData
        
        for collection in collectionList {
            let landmarks = landmarks(for: collection.landmarkIds)
            collection.landmarks = landmarks
        }
        
        guard let favorites = collectionList.first(where: { $0.id == 1001 }) else {
            fatalError("Favorites collection missing from JSON data.")
        }
        favoritesCollection = favorites

        userCollections = collectionList.filter { collection in
            return collection.id != 1001
        }
    }

    var filteredLandmarks: [Landmark] = []

    func filterLandmarks(term: String, tokens: [SearchToken]) {
        var results: [Landmark] = []
        if tokens.contains(.image) {
            let landmarks = landmarks.filter {
                $0.id != 1005
            }.shuffled()

            results = [landmarksById[1005]!]
                + landmarks
        } else {
            results = landmarks.filter {
                $0.name.contains(term) ||
                $0.description.contains(term)
            }
        }

        self.filteredLandmarks = results
    }

    func addUserCollection() {
        var nextUserCollectionId: Int = 1002
        if let lastUserCollectionId = userCollections.sorted(by: { lhs, rhs in lhs.id > rhs.id }).first?.id {
            nextUserCollectionId = lastUserCollectionId + 1
        }
        
        let newCollection = Collection(id: nextUserCollectionId,
                                       name: "New Collection",
                                       description: "Add a description for your collection here...",
                                       landmarkIds: [],
                                       landmarks: [])
        userCollections.append(newCollection)
    }
    
    func remove(_ collection: Collection) {
        self.remove(collection: collection.id)
    }

    func remove(collection id: Int) {
        guard let collection = collection(id: id) else {
            return
        }

        if let indexInUserCollections = userCollections.firstIndex(where: { $0.id == id }) {
            userCollections.remove(at: indexInUserCollections)

            recentlyDeletedCollections[collection.id] = collection
        }
    }

    func restoreCollection(collection id: Int) {
        guard let collection = recentlyDeletedCollections[id] else {
            return
        }

        recentlyDeletedCollections.removeValue(forKey: id)

        self.userCollections.append(collection)
    }

    func collection(id: Int) -> Collection? {
        return self.userCollections.first { $0.id == id }
    }

    func collection(_ collection: Collection, contains landmark: Landmark) -> Bool {
        var collectionContainsLandmark: Bool = false
        
        if collection.landmarks.firstIndex(of: landmark) != nil {
            collectionContainsLandmark = true
        }
        
        return collectionContainsLandmark
    }

    func collectionsContaining(_ landmark: Landmark) -> [Collection] {
        return userCollections.filter { collection in
            self.collection(collection, contains: landmark)
        }
    }

    func add(_ landmark: Landmark, to collection: Collection) {
        if collection.landmarks.firstIndex(of: landmark) != nil {
            return
        }

        collection.landmarks.append(landmark)
    }

    private func landmarksByContinent(from landmarks: [Landmark]) -> [Continent: [Landmark]] {
        var landmarksByContinent: [Continent: [Landmark]] = [:]
        
        for landmark in landmarks {
            guard let continent = Continent(rawValue: landmark.continent) else { continue }

            if landmarksByContinent[continent] == nil {
                landmarksByContinent[continent] = [landmark]
            } else {
                landmarksByContinent[continent]?.append(landmark)
            }
        }

        return landmarksByContinent
    }
    
    func landmarks(for landmarkIds: [Int]) -> [Landmark] {
        var landmarks: [Landmark] = []
        for landmarkId in landmarkIds {
            if let landmark = landmarksById[landmarkId] {
                landmarks.append(landmark)
            }
        }
        return landmarks
    }
    
    nonisolated private func fetchMapItems(for landmarks: [Landmark]) async throws -> [Int: MKMapItem] {
        var fetchedMapItemsByLandmarkId: [Int: MKMapItem] = [:]
        
        for landmark in landmarks {
            guard let placeID = landmark.placeID else { continue }
            
            guard let identifier = MKMapItem.Identifier(rawValue: placeID) else { continue }
            let request = MKMapItemRequest(mapItemIdentifier: identifier)
            if let mapItem = try? await request.mapItem {
                fetchedMapItemsByLandmarkId[landmark.id] = mapItem
            }
        }
        
        return fetchedMapItemsByLandmarkId
    }

    func getCrowdStatus(landmarkID: Int) -> Int {
        return landmarkOccupancy[landmarkID]!
    }
}

extension ModelData {
    enum Continent: String, CaseIterable {
        case africa = "Africa"
        case antarctica = "Antarctica"
        case asia = "Asia"
        case australiaOceania = "Australia/Oceania"
        case europe = "Europe"
        case northAmerica = "North America"
        case southAmerica = "South America"
    }
    
    static let orderedContinents: [Continent] = [.asia, .africa, .antarctica, .australiaOceania, .northAmerica, .southAmerica]
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

