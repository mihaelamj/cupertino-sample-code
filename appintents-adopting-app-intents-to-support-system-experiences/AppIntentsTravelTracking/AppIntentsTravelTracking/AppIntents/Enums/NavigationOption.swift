/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An app enum for different sections of the app.
*/

import AppIntents
import SwiftUI

enum NavigationOption: String, Hashable, Identifiable, CaseIterable, AppEnum {
    case landmarks
    case map
    case collections

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(
            name: LocalizedStringResource("Navigation Option", table: "AppIntents"),
            numericFormat: "\(placeholder: .int) navigation options"
        )
    }

    static let caseDisplayRepresentations = [
        NavigationOption.landmarks: DisplayRepresentation(
            title: "Landmarks",
            image: .init(systemName: "building.columns")
        ),
        NavigationOption.map: DisplayRepresentation(
            title: "Map",
            image: .init(systemName: "map")
        ),
        NavigationOption.collections: DisplayRepresentation(
            title: "Collections",
            image: .init(systemName: "book.closed")
        )
    ]

    var id: String { rawValue }
    
    var name: LocalizedStringResource {
        switch self {
        case .landmarks: LocalizedStringResource("Landmarks", comment: "Tab title for 'Landmarks' shown in the sidebar.")
        case .map: LocalizedStringResource("Map", comment: "Tab title for 'Map' shown in the sidebar.")
        case .collections: LocalizedStringResource("Collections", comment: "Tab title for 'Collections' shown in the sidebar.")
        }
    }
    
    var symbolName: String {
        switch self {
        case .landmarks: "building.columns"
        case .map: "map"
        case .collections: "book.closed"
        }
    }
    
    @MainActor @ViewBuilder func viewForPage() -> some View {
        switch self {
        case .landmarks: LandmarksView()
        case .map: MapView()
        case .collections: CollectionsView()
        }
        
    }
}
