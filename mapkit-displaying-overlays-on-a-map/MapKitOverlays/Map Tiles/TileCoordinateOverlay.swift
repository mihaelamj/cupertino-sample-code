/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tile overlay that labels tiles with the tile path and zoom level.
*/

import Foundation
import MapKit

/**
 To create tiles that match the curvature of the map, use the EPSG:3857 spherical Mercator projection coordinate system.
 
 To understand this coordinate system, it's helpful to visualize it to see where the tile boundaries are,
 and also which coordinates relate to different parts of the world, which this subclass of `MKTileOverlay` provides.
 It's also helpful to understand the relationship between the tile coordinate and the zoom level — for every increase in zoom level,
 the number of tiles increases by a power of 2.
 
 Example:
 Consider tile (10, 12) at zoom level 6, and then zooming in to zoom level 7, and zooming out to zoom level 5.
    At zoom level 7, four tiles replace the area that the tile (10,12) covers at zoom level 6, including tile (20, 24).
    Note that (20, 24) is double the coordinates of the previous tile at zoom level 6.
        (10, 12) becomes:
        (20, 24) (21, 24)
        (20, 25) (21, 25)
        
    When going from zoom level 6 to zoom level 5, the tile coordinates are halved, and four tiles become one tile:
        (10, 12) (11, 12)
        (10, 13) (11, 13)
        become: (5,6)
 */
class TileCoordinateOverlay: MKTileOverlay {
    
    /// Use a 2 x 2 grid of colors so the same color is never adjacent to itself, to make the tile boundaries obvious.
    private let tileColors = [ [#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 0.7), #colorLiteral(red: 0.9921568627, green: 0.6823529411, blue: 0.0039215686, alpha: 0.7)],
                               [#colorLiteral(red: 1.0000000000, green: 0.9450980392, blue: 0.3372549019, alpha: 0.7), #colorLiteral(red: 0.5499670582, green: 0.9739212428, blue: 0.2905708413, alpha: 0.7)] ]
    
    override func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        /**
         Usually, you provide prerendered tiles and either load them from disk or the network rather than creating them on-demand, as they are here.
         Because the purpose of this tile overlay is to visualize the tile paths and zoom levels for all tiles worldwide, providing a prerendererd
         tile set for the entire world is infeasible.
         */
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        let data = renderer.pngData { context in
            
            let color = tileColors[path.x % 2][path.y % 2]
            color.setFill()
            context.fill(CGRect(origin: .zero, size: tileSize))
            
            let text = """
                        Tile Path (\(path.x), \(path.y))
                        Zoom: \(path.z)
                       """
            
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]
            text.draw(in: CGRect(origin: CGPoint(x: 10, y: 10), size: tileSize), withAttributes: attributes)
        }
        
        return data
    }
}
