/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration of navigation options in the app.
*/

import SwiftUI

/// An enumeration of navigation options in the app.
enum NavigationOptions: Equatable, Hashable, Identifiable {
    /// A case that represents viewing the app's landmarks, organized by continent.
    case landmarks
    /// A case that represents viewing the app's landmarks on a map.
    case map
    /// A case that represents viewing a person's favorite landmarks and other custom landmark collections.
    case collections
    
    static let mainPages: [NavigationOptions] = [.landmarks, .map, .collections]
    
    var id: String {
        switch self {
        case .landmarks: return "Landmarks"
        case .map: return "Map"
        case .collections: return "Collections"
        }
    }
    
    var name: LocalizedStringResource {
        switch self {
        case .landmarks: LocalizedStringResource("Landmarks", comment: "Title for the Landmarks tab, shown in the sidebar.")
        case .map: LocalizedStringResource("Map", comment: "Title for the Map tab, shown in the sidebar.")
        case .collections: LocalizedStringResource("Collections", comment: "Title for the Collections tab, shown in the sidebar.")
        }
    }
    
    var symbolName: String {
        switch self {
        case .landmarks: "building.columns"
        case .map: "map"
        case .collections: "book.closed"
        }
    }
    
    /// A view builder that the split view uses to show a view for the selected navigation option.
    @MainActor @ViewBuilder func viewForPage() -> some View {
        switch self {
        case .landmarks: LandmarksView()
        case .map: MapView()
        case .collections: CollectionsView()
        }
        
    }
}
