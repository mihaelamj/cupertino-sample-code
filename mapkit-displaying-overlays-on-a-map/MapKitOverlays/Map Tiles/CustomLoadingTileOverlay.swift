/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tile overlay that demonstrates how to customize loading behaviors for the best performance.
*/

import Foundation
import MapKit

class CustomLoadingTileOverlay: MKTileOverlay {
    
    private var urlSession: URLSession!
    
    override init(urlTemplate: String?) {
        super.init(urlTemplate: urlTemplate)
        
        /**
         This class focuses on customizing the tile-loading behavior for a server, and you can also implement custom loading behavior for tiles
         on disk, such as when you need to fetch them from a local SQLite database. The comments in `loadTile(at:)` are relevant regardless of
         the loading mechanism.
         */
        setupURLSession()
    }
    
    private func setupURLSession() {
        /**
         Loading map tiles is highly asynchronous, and can require issuing over 100 HTTP requests to get all visible map tiles if the `MKMapView`
         displaying the tiles fills a large screen. If the user pans or zooms a large map rapidly, the app might need to issue hundreds more HTTP
         requests within a short time frame to load more map tiles.
         
         To gracefully handle large bursts of HTTP requests, map tile servers need to be highly responsive, enabling you to use `MKTileOverlay`
         directly, without needing a subclass. Before writing your own class with a customized `URLSession` for loading map tiles, see if MapKit's
         built-in loading approach meets your needs.
         
         If your map tile server has less optimal performance characteristics, you can subclass `MKTileOverlay` and provide your own `URLSession`
         that you fine-tune to match the server capabilities. When using your own `URLSession` to load tiles, start with the `default`
         configuration, and apply the minimum amount of targeted changes to the default configuration according to your specific needs.
         */
        let config = URLSessionConfiguration.default
        
        /**
         If the map tile server supports HTTP/1.1, pipelining reduces the number of network connections that need to be open to the server by
         allowing multiple requests to use the same connection. This improves performance by removing the time required to set up and tear down
         individual HTTP connections on every tile request. HTTP/2 and HTTP/3 multiplex requests remove the need for using multiple connections
         with pipelining in an enabled state.
         */
        config.httpShouldUsePipelining = true
        
        /**
         If the map tile server supports HTTP/1.1, using higher numbers of simultaneous connections to the server may improve the user experience
         by reducing how much time they need to wait for all visible map tiles to load. For example, if a map on a large screen requires 100 map
         tiles to fully fill in the map, and each tile takes 1 second to return from the server while using four simultaneous connections, it might
         take `(100 tiles / 4 connections) * 1 second = 25 seconds` to fully populate the visible map tiles. If the user pans
         or zooms the map while the tiles load, triggering the loading of even more tiles based on the map adjustments,
         they need to wait even longer, as the new map tile requests might queue behind the other tile requests still in progress.
         
         HTTP/2 and HTTP/3 multiplex requests remove the need for using multiple connections.
         
         When fine-tuning this number, consult your server for the optimal number of connections coming from one host, in
         addition to considering the size of the map view and how many map tiles may be visible and load at once.
         */
        config.httpMaximumConnectionsPerHost = 6
                
        /**
         MapKit caches loaded map tiles, but in some situations, implementing additional caching can improve performance.
         For example, if you're working with a slow server, caching tiles to memory or to disk reduces the number of requests
         for the same tile, reducing overall waiting in the app. If a user repeatedly comes back to the same map
         over multiple app launches, caching tiles to disk reduces the overall amount of network traffic required to view
         the same map often.
         
         `URLSession` consults a provided `URLCache` when loading a URL, and returns the resource from the cache if it's
         present, so you don't need to provide your own network caching implementation. You can fine-tune the `URLCache` to meet your
         specific needs for caching to memory, disk, or both, before evicting tiles from the cache.
         */
        config.urlCache = URLCache(memoryCapacity: 100_000, diskCapacity: 512_000_000)
        
        // Create the `URLSession` and customize the `URLSessionConfiguration` to meet specific needs.
        urlSession = URLSession(configuration: config)
    }
    
    override func loadTile(at path: MKTileOverlayPath) async throws -> Data {
        // When initalizing the `MKTileOverlay`, you provide a template URL with placeholder tokens for parameters, like the tile path.
        // Create the final URL by replacing those placeholders with the requested tile path.
        let urlToLoad = url(forTilePath: path)
        
        // Request the data. If an error occurs, the system throws the error to MapKit.
        let result = try await urlSession.data(from: urlToLoad)
        
        /**
         MapKit supports tiles in common image formats, including PNG, JPEG, and HEIC. If the retrieved tile is in
         a common image format, the `Data` that returns from the `URLSession` contains the image bytes, which you directly
         return to MapKit to display the tile. Processing the data that the `URLSession` returns into an image, or
         converting the data to a different image format, is rarely necessary.
         */
        let mapTileData = result.0
        
        /**
         Sleep for 0.5 seconds as an example of a server that has slow response times, even with an excellent network connection.
         Try adjusting different properties in `setupURLSession()` to see the difference those settings make in the user experience.
         Also make sure to test under different conditions with the Network Link Conditioner.
         */
        usleep(500_000)
        
        /**
         This function is the async version of `loadTile(at:)`, enabling you to use the `return` keyword to return the tile data to MapKit.
         
         If your custom tile loading implementation uses the `loadTile(at:completion:)` function with the completion handler instead,
         avoid dispatching to the main queue before calling the completion handler. MapKit calls this function across multiple concurrent
         background queues, and dispatching requests back to a single serial queue, such as the main queue, reduces performance.
         */
        return mapTileData
    }
}
