/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view containing a map that shows details about places that a person taps on.
*/

@preconcurrency import MapKit
import OSLog
import SwiftUI

struct MapView: View {
    
    @Environment(LocationService.self) private var locationService
    @Environment(MapModel.self) private var mapModel
    
    /// The `MapCameraPosition` describes how to position the map’s camera within the map.
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    /// The currently selected map feature.
    @State private var selection: MapSelection<MKMapItem>?
    
    /// - Tag: SelectableFeature
    var body: some View {
        @Bindable var mapModel = mapModel
        
        Map(position: $mapCameraPosition, selection: $selection) {
            // Display the user's location. This sample enables the reduced accuracy setting in the Info.plist, so
            // the user's approximate location displays as a circular region rather than as a specific point.
            UserAnnotation()
            
            /*
             Treat each `MKMapItem` object as unique, using `\.self` for the identity. The `identifier` property of `MKMapItem`
             is an optional value, and the meaning of the identifier for `MKMapItem` doesn't have the same semantics as
             the `Identifable` protocol that `ForEach` requires.
             */
            ForEach(mapModel.searchResults, id: \.self) { result in
                /*
                 Display each search result as an annotation on the map using MapKit's default
                 annotation style, including iconography based on the map item's point-of-interest category.
                 The `tag` modifier enables selection of these items through the `selection` binding.
                 */
                Marker(item: result)
                    .tag(MapSelection(result))
            }
            
            /*
             This selection accessory modifier allows people to tap on the annotations that the app adds to the map and get more detailed
             information on the annotation, which displays as either a sheet or a callout according to the `style` parameter. Along with
             the `selection` binding, this determines which annotation to display additional information for.
             
             This modifier differs from the `mapFeatureSelectionAccessory(:_) modifier, which enables the same selection
             behaviors on map features, such as points of interest that `Map` displays.
             */
            .mapItemDetailSelectionAccessory(.automatic)
        }
        
        // Use the standard map style, with an option to display specific point-of-interest categories.
        .mapStyle(.standard(pointsOfInterest: mapModel.searchConfiguration.pointOfInterestOptions.categories))
        
        // Only allow selection for points of interest, and disable selection of other labels, like city names.
        .mapFeatureSelectionDisabled { feature in
            feature.kind != MapFeature.FeatureKind.pointOfInterest
        }
        
        /*
         The selection accessory allows people to tap on map features and get more detailed information, which displays
         as either a sheet or a callout according to the `style` parameter. Along with the `selection` binding, this determines
         which feature to display additional information for.
         
         This modifier differs from the `mapItemDetailSelectionAccessory(:_) modifier, which enables the same selection
         behaviors on annotations that the app adds to `Map` for search results.
         */
        .mapFeatureSelectionAccessory(.automatic)
        
        .onMapCameraChange(frequency: .onEnd) { cameraContext in
            // When the camera changes position, such as when a person moves or zooms the map, update
            // the region the app uses for searching to reflect the changes to the visible map region.
            mapModel.searchConfiguration.region = cameraContext.region
        }
        .onChange(of: locationService.currentLocation, initial: true) {
            /*
             If a person chooses to grant access to their location, adjust the map camera to center the map
             on their location, and display the surrounding 1,500 meter region. The app uses the visible map
             region as part of its criteria for search results, so this region allows the app to show search
             results within a reasonable distance of the person's location.
             */
            mapCameraPosition = .region(MKCoordinateRegion(center: locationService.currentLocation.coordinate,
                                                           latitudinalMeters: 1500,
                                                           longitudinalMeters: 1500))
        }
        .onChange(of: mapModel.searchResults) {
            // Adjust the map camera to make all of the annotations representing the search results visible.
            mapCameraPosition = .automatic
        }
        .onChange(of: selection) { _, newSelection in
            updateModelWithSelectedFeature(newSelection)
        }
        .onChange(of: mapModel.selectedMapItem) { _, newValue in
            // Closes the detail view when another object changes the model state, to prevent multiple
            // detail views from being present on screen at once.
            if newValue == nil {
                selection = nil
            }
        }
    }
    
    /// Take the map's selection and update the map model to inform other objects tracking the selected map item of the new value.
    private func updateModelWithSelectedFeature(_ selection: MapSelection<MKMapItem>?) {
        if let mapItem = selection?.value {
            // The person has selected an annotation, such as a search result.
            mapModel.selectedMapItem = mapItem
        } else if let feature = selection?.feature {
            // The person has selected a map feature, such as a point of interest. Because the map feature doesn't contain the
            // details as an `MKMapItem`, request a map item for the feature.
            Task {
                let request = MKMapItemRequest(feature: feature)
                var mapItem: MKMapItem? = nil
                do {
                    mapItem = try await request.mapItem
                    mapModel.selectedMapItem = mapItem
                } catch let error {
                    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Map Item Requests")
                    logger.error("Getting map item from map feature failed. Error: \(error.localizedDescription)")
                }
            }
        } else {
            mapModel.selectedMapItem = nil
        }
    }
}
