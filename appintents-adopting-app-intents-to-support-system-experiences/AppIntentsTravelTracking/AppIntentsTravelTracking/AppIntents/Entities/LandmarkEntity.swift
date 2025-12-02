/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App entity representing a landmark.
*/

import AppIntents
import CoreSpotlight
import CoreTransferable
import SwiftUI
import PDFKit

struct LandmarkEntity: IndexedEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(
            name: LocalizedStringResource("Landmark", table: "AppIntents", comment: "The type name for the landmark entity"),
            numericFormat: "\(placeholder: .int) landmarks"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(continent)",
            image: .init(data: try! self.thumbnailRepresentationData)
        )
    }

    static let defaultQuery = LandmarkEntityQuery()

    var id: Int { landmark.id }

    @ComputedProperty(indexingKey: \.displayName)
    var name: String { landmark.name }

    // Maps the description variable to the Spotlight indexing key `contentDescription`.
    @ComputedProperty(indexingKey: \.contentDescription)
    var description: String { landmark.description }

    // Maps the continent variable to a custom Spotlight indexing key.
    @ComputedProperty(
        customIndexingKey: CSCustomAttributeKey(
            keyName: "com_AppIntentsTravelTracking_LandmarkEntity_continent"
        )!
    )
    var continent: String { landmark.continent }

    @DeferredProperty
    var crowdStatus: Int {
        get async throws {
            await modelData.getCrowdStatus(self)
        }
    }

    var landmark: Landmark
    var modelData: ModelData

    init(landmark: Landmark, modelData: ModelData) {
        self.modelData = modelData
        self.landmark = landmark
    }
}

extension LandmarkEntity: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { @MainActor landmark in
            let url = URL.documentsDirectory.appending(path: "\(landmark.name).pdf")

            let renderer = ImageRenderer(content: VStack {
                Image(landmark.landmark.backgroundImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text(landmark.name)
                Text("Continent: \(landmark.continent)")
                Text(landmark.description)
            }.frame(width: 600))

            renderer.render { size, renderer in
                var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)

                guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                    return
                }
                pdf.beginPDFPage(nil)
                renderer(pdf)
                pdf.endPDFPage()
                pdf.closePDF()
            }

            return .init(url)
        }

        DataRepresentation(exportedContentType: .image) {
            try $0.imageRepresentationData
        }

        DataRepresentation(exportedContentType: .plainText) {
            """
            Landmark: \($0.name)
            Description: \($0.description)
            """.data(using: .utf8)!
        }
    }
}

@MainActor
struct LandmarkEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery {
    @Dependency var modelData: ModelData

    func suggestedEntities() async throws -> [LandmarkEntity] {
        modelData.favoriteLandmarkEntities()
    }

    func entities(for identifiers: [LandmarkEntity.ID]) async throws -> [LandmarkEntity] {
        modelData
            .landmarks(for: identifiers)
            .map {
                LandmarkEntity(landmark: $0, modelData: modelData)
            }
    }

    func entities(matching: String) async throws -> [LandmarkEntity] {
        modelData
            .landmarks
            .filter { $0.name.contains(matching) || $0.description.contains(matching) }
            .map {
                LandmarkEntity(landmark: $0, modelData: modelData)
            }
    }

    func allEntities() async throws -> [LandmarkEntity] {
        modelData.landmarkEntities
    }
}

extension LandmarkEntity {
    var sharePreview: SharePreview<Never, Image> {
        SharePreview(name, icon: Image(landmark.thumbnailImageName))
    }
}
