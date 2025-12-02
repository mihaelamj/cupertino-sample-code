/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Additional functionality for the class that manages the app's data.
*/

import Foundation

extension ModelData {
    func isFavorite(_ landmarkEntity: LandmarkEntity) -> Bool {
        guard let landmark = landmarksById[landmarkEntity.id] else {
            return false
        }
        return isFavorite(landmark)
    }

    func addFavorite(_ landmarkEntity: LandmarkEntity) {
        guard let landmark = landmarksById[landmarkEntity.id] else {
            return
        }
        addFavorite(landmark)
    }

    func removeFavorite(_ landmarkEntity: LandmarkEntity) {
        guard let landmark = landmarksById[landmarkEntity.id] else {
            return
        }
        removeFavorite(landmark)
    }

    func updateFavorite(_ isFavorite: Bool, landmarkEntity: LandmarkEntity) {
        if isFavorite {
            addFavorite(landmarkEntity)
        } else {
            removeFavorite(landmarkEntity)
        }
    }

    var landmarkEntities: [LandmarkEntity] {
        landmarks.map {
            LandmarkEntity(landmark: $0, modelData: self)
        }
    }

    func landmarkEntities(for landmarkIds: [Int]) -> [LandmarkEntity] {
        landmarks(for: landmarkIds).map {
            LandmarkEntity(landmark: $0, modelData: self)
        }
    }

    func landmarkEntity(id: Int) throws -> LandmarkEntity {
        guard let landmarkEntity = landmarkEntities(for: [id]).first else {
            throw ShowClosestLandmarkError.noLandmarkFound
        }

        return landmarkEntity
    }

    func favoriteLandmarks() -> [Landmark] {
        landmarks
            .filter { self.isFavorite($0) }
    }

    func favoriteLandmarkEntities() -> [LandmarkEntity] {
        favoriteLandmarks().map {
            LandmarkEntity(landmark: $0, modelData: self)
        }
    }

    func findClosestLandmark() async throws -> LandmarkEntity {
        guard let landmark = landmarksById[1005] else {
            throw ShowClosestLandmarkError.noLandmarkFound
        }
        
        return LandmarkEntity(landmark: landmark, modelData: self)
    }

    func archiveCollection(_ collection: CollectionEntity) async throws -> CollectionEntity {
        let collection = self.collection(id: collection.id)!
        collection.name = "[Archived] \(collection.name)"

        return CollectionEntity(collection: collection, modelData: self)
    }

    func deleteCollection(_ collection: CollectionEntity) async throws {
        self.remove(collection: collection.id)
    }

    func restoreCollection(_ collection: CollectionEntity) {
        self.restoreCollection(collection: collection.id)
    }

    func getCrowdStatus(_ landmark: LandmarkEntity) -> Int {
        return landmarkOccupancy[landmark.id]!
    }

    func isOpen(_ landmark: LandmarkEntity) -> Bool {
        return true
    }
}

private enum ShowClosestLandmarkError: Error, CustomLocalizedStringResourceConvertible {
    case noLandmarkFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noLandmarkFound:
            return "Unable to find nearest landmark."
        }
    }
}
