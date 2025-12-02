/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `MapDataResults` object loads and stores object values of a single MapKit type.
*/

import Foundation
import MapKit

/// An actor that safely loads (or attempts to load) object values from MapKit.
@MainActor
final class MapDataResults<Key: Hashable, Value: Sendable> {
    
    /// The retrieval state of an item identified by its key.
    enum LoadingStatus {
        case loading(Task<Value, Error>)
        case loaded(Result<Value, Error>)
    }
    
    /// Items that are loading or already completed loading.
    var mapDataResults: [Key: LoadingStatus] = [:]
    
    /// Gets the item for a specified key, using the supplied closure to load it if necessary.
    /// - parameter key: The item to get.
    /// - parameter loader: A closure that can load the item's value asynchronously.
    /// - returns: The result of loading the item.
    func result(for key: Key, loader: @Sendable @escaping () async throws -> Value) async -> Result<Value, Error> {
        
        // Choose an action based on the current state of the existing results.
        switch mapDataResults[key] {

        case nil:
            
            // The item was not found, so create a task to load it. The existence of this task prevents the
            // creation of additional (duplicate) tasks for this item.
            let task = Task {
                try await loader()
            }
            mapDataResults[key] = .loading(task)
            
            /*
             This system suspends execution of this method at the following `await` statement until the task is complete.
             This allows additional actor functions to execute before we resume execution of this function.
             
             However, because the `mapDataResults` dictionary already contains a value for this item ID,
             any additional functions won't attempt to modify the dictionary. For that reason,
             the dictionary still contains the `.loading` case after resuming, and it's safe to replace
             it with the result of loading (either a value or an error).
             */
            let result = await task.result
            mapDataResults[key] = .loaded(result)
            return result

        case .loading(let task):
            
            // The item is already being loaded. In this case, get the result by awaiting the in-progress task.
            return await task.result
            
        case .loaded(let result):
            
            // The item has loaded successfully, or has failed to load.
            return result
        }
    }
    
    /// Synchronously gets the result of loading the specified item, if it has been loaded or has failed to load.
    /// - parameter key: The item to get.
    /// - returns: A `Result` wrapping the value or the error that resulted from loading, or `nil` if loading has not completed.
    func availableResult(for key: Key) -> Result<Value, Error>? {
        switch mapDataResults[key] {
            
        case nil, .loading:
            
            // The item is not in the existing results.
            return nil
            
        case .loaded(let result):
            
            // The item has loaded successfully, or has failed to load.
            return result
        }
    }
    
    /// Gets the value of an item for which loading has completed, or at least been started.
    /// - parameter key: The item to get.
    /// - returns: The result of loading the item.
    /// - note: This function intentionally crashes with a force-unwrap if loading has never been started because that's a program logic error,
    ///         and there's no reasonable recovery action.
    func preloadedResult(for key: Key) async -> Result<Value, Error> {
        switch mapDataResults[key]! {
            
        case .loading(let task):
            
            // The item is already being loaded. In this case, get the result by awaiting the in-progress task.
            return await task.result
            
        case .loaded(let result):
            
            // The item has loaded successfully, or has failed to load.
            return result
        }
    }
}

/// Errors resulting from `MapKit` functions.
enum MapDataError: LocalizedError {
    case mapSearchFailed(MapItemID, String?)
    case mapSearchError(MapItemID, String?, Error)
    case sceneRequestFailed(MapItemID, String?)
    case sceneRequestError(MapItemID, String?, Error)
    
    var errorDescription: String? {
        switch self {
        case .mapSearchFailed(let locationID, let locationName):
            let location = locationName ?? "<Unknown Location Name>"
            return String(localized: "No map item was found for itemID \(locationID.uniqueID) (\(location)")
        case .mapSearchError(let locationID, let locationName, let error):
            let location = locationName ?? "<Unknown Location Name>"
            return String(localized: "Map item search failed for itemID \(locationID.uniqueID) (\(location) : \(error.localizedDescription)")
        case .sceneRequestFailed(let locationID, let locationName):
            let location = locationName ?? "<Unknown Location Name>"
            return String(localized: "No Look Around scene was found for itemID \(locationID.uniqueID) (\(location)")
        case .sceneRequestError(let locationID, let locationName, let error):
            let location = locationName ?? "<Unknown Location Name>"
            return String(localized: "Look Around scene request failed for itemID \(locationID.uniqueID) (\(location): \(error.localizedDescription)")
        }
    }
}
