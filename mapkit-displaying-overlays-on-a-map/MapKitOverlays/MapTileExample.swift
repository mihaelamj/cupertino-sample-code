/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example showing how to use map tile overlays.
*/

import Foundation
import MapKit

extension OverlayViewController {
    
    /// Displays a tile overlay that shows the tile boundaries and labels the tile coordinates.
    func displayTileCoordinateExample() {
        title = "Tile Coordinates"
        
        let coordinateOverlay = TileCoordinateOverlay()
        mapView.addOverlay(coordinateOverlay, level: .aboveLabels)
    }
    
    /// Displays a tile overlay for the map tiles bundled with the app.
    func displayLocalTileExample() {
        title = "Local Map Tiles"
        
        /**
         The tiles in this sample project show shaded topographic relief from The National Map of the United States Geological Survey.
         More information on this tile set is available at `https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/`.
         */
        /// - Tag: tile_url
        let tileDirectoryName = "tileData"
        guard let resourcePath = Bundle.main.resourcePath else { return }
        let localPath = "file://\(resourcePath)/\(tileDirectoryName)/{z}/{x}/{y}.jpg"
        let tileOverlay = MKTileOverlay(urlTemplate: localPath)
        
        /**
         Because the tiles in this project only cover a small area of the map for specific zoom scales, leave the default map content
         visible to fill in the areas beyond what the provided tiles cover. You can also consider setting `cameraBoundary` to lock the map to
         an area with the tiles in the app.
         */
        tileOverlay.canReplaceMapContent = false
        mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: LocationData.northernCaliforniaRegion)
        mapView.region = LocationData.northernCaliforniaRegion
        
        /**
         Because there are only a limited amount of tiles included locally with the sample app, specificy a zoom range to limit
         tile requests to that zoom range of available tiles. This only restricts loading of tiles in that zoom range, but the user
         is still able to zoom the map unless you specify an `MKMapView.CameraZoomRange` on the map view.
        */
        tileOverlay.minimumZ = 8
        tileOverlay.maximumZ = 9
        
        mapView.addOverlay(tileOverlay, level: .aboveLabels)
    }
    
    /// Displays a tile overlay for map tiles that load from a server.
    func displayServerTileExample() {
        title = "Map Tiles From a Server"
        
        createAndDisplayServerMapTileOverlays()
    }
    
    /**
     A template URL for map tiles from the National Hydrography Dataset of the United States Geological Survey.
     These map tiles place an emphasis on rivers and bodies of water. These tiles contain an alpha channel, allowing you to place them
     over other map tiles. For example, when placing over shaded topographic relief map tiles, the relationship between
     valleys and rivers is visible.
     
     More information on this tile set is available at `https://basemap.nationalmap.gov/arcgis/rest/services/USGSHydroCached/MapServer/`.
     */
    private static let HydrographyTilePathTemplate = "https://basemap.nationalmap.gov/arcgis/rest/services/USGSHydroCached/MapServer/WMTS/tile/1.0.0/USGSHydroCached/default/default028mm/{z}/{y}/{x}"
    
    /**
     A template URL for map tiles showing shaded topographic relief from The National Map of the United States Geological Survey.
     These map tiles place an emphasis on terrain, and highlight the differences between plains and mountains.
     
     More information on this tile set is available at `https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/`.
     */
    private static let ShadedReliefTilePathTemplate = "https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/WMTS/tile/1.0.0/USGSShadedReliefOnly/default/default028mm/{z}/{y}/{x}"
    
    private func createAndDisplayServerMapTileOverlays(includeShadedRelief: Bool = true, includeHydrography: Bool = true) {
        removeOverlays()
        
        /**
         The URL template contains tokens for tile path parameters, which the system substitutes with specific tile path values when loading them.
         The tokens are `{x}` and `{y}` for the tile path, `{z}` for the map zoom level, and `{scale}` for the resolution of the tile.
         */
        let reliefTileOverlay = MKTileOverlay(urlTemplate: OverlayViewController.ShadedReliefTilePathTemplate)
        let hydroTileOverlay = MKTileOverlay(urlTemplate: OverlayViewController.HydrographyTilePathTemplate)
        
        /**
         Set this property to `true` as a hint that the map view doesn't need to render the map under this tile overlay.
         Don’t set this property for tile overlays that contain alpha components to show the underlying map in certain areas.
         */
        reliefTileOverlay.canReplaceMapContent = true
        
        /**
         The order of the overlays matter: the hydrography tiles contain an alpha channel, so you need to place them over the shaded relief tiles,
         which don't have an alpha channel.
         */
        if includeShadedRelief {
            mapView.addOverlay(reliefTileOverlay, level: .aboveLabels)
        }
        
        if includeHydrography {
            if !includeShadedRelief {
                /**
                 The hydrography tiles have an alpha channel, making them hard to see against the base map when the shaded relief tiles aren't
                 in place. Blocking out the base map content helps make the content of the hydrography tiles clear.
                 */
                hydroTileOverlay.canReplaceMapContent = true
            }
            mapView.addOverlay(hydroTileOverlay, level: .aboveLabels)
        }
        
        mapView.region = LocationData.northernCaliforniaRegion
        
        /// Create a menu for controlling the different map tile overlays.
        layerMenuButton.menu = UIMenu(title: "Configure Overlays", children: [
            UIAction(title: "Hydrography Overlay",
                     image: UIImage(systemName: "water.waves"),
                     state: includeHydrography ? .on : .off) { _ in
                         // Reverse the current state.
                         var value = includeHydrography
                         value.toggle()
                         self.createAndDisplayServerMapTileOverlays(includeShadedRelief: includeShadedRelief, includeHydrography: value)
            },
            UIAction(title: "Shaded Relief Overlay",
                     image: UIImage(systemName: "mountain.2"),
                     state: includeShadedRelief ? .on : .off) { _ in
                         // Reverse the current state.
                         var value = includeShadedRelief
                         value.toggle()
                         self.createAndDisplayServerMapTileOverlays(includeShadedRelief: value, includeHydrography: includeHydrography)
            }
        ])
    }
    
    /// Displays a tile overlay for map tiles that load from a server using a customized loading implementation with caching.
    /// - Tag: add_overlay_level
    func displayCustomLoadingTileExample() {
        title = "Customized Map Tile Loading"
        
        let reliefTileOverlay = CustomLoadingTileOverlay(urlTemplate: OverlayViewController.ShadedReliefTilePathTemplate)
        let hydroTileOverlay = CustomLoadingTileOverlay(urlTemplate: OverlayViewController.HydrographyTilePathTemplate)
        
        mapView.addOverlay(reliefTileOverlay, level: .aboveLabels)
        mapView.addOverlay(hydroTileOverlay, level: .aboveLabels)
        
        mapView.region = LocationData.northernCaliforniaRegion
    }
   
    func createTileRenderer(for overlay: MKTileOverlay) -> MKTileOverlayRenderer {
        /**
         For tile overlays, there's little need to subclass the overlay renderer, unlike other types of custom overlays.
         This sample always uses the default tile renderer implementation.
         */
        let tileRenderer = MKTileOverlayRenderer(tileOverlay: overlay)
        return tileRenderer
    }
}
