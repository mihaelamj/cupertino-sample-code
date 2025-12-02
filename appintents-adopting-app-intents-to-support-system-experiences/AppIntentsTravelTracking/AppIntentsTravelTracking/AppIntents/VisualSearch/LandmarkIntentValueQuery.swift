/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A query that adds support for visual intelligence search.
*/

#if canImport(VisualIntelligence)
import AppIntents
import VideoToolbox
import VisualIntelligence

@UnionValue
enum VisualSearchResult {
    case landmark(LandmarkEntity)
    case collection(CollectionEntity)
}

struct LandmarkIntentValueQuery: IntentValueQuery {

    @Dependency var modelData: ModelData

    func values(for input: SemanticContentDescriptor) async throws -> [VisualSearchResult] {

        guard let pixelBuffer: CVReadOnlyPixelBuffer = input.pixelBuffer else {
            return []
        }

        let landmarks = try await modelData.search(matching: pixelBuffer)

        return landmarks
    }
}

extension ModelData {
    /**
     This method contains the search functionality that takes the pixel buffer that visual intelligence provides
     and uses it to find matching app entities. To keep this example app easy to understand, this function always
     returns the same landmark entity.
    */
    func search(matching pixels: CVReadOnlyPixelBuffer) throws -> [VisualSearchResult] {
        let landmarks = landmarkEntities.filter {
            $0.id != 1005
        }.map {
            VisualSearchResult.landmark($0)
        }.shuffled()

        let collections = userCollections
            .filter {
                $0.landmarks.contains(where: { $0.id == 1005 })
            }
            .map {
                CollectionEntity(collection: $0, modelData: self)
            }
            .map {
                VisualSearchResult.collection($0)
            }

        return [try! .landmark(landmarkEntity(id: 1005))]
            + collections
            + landmarks
    }
}

#endif
