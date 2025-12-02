/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that used to mimic fetching data asynchronously.
*/

import Foundation

/// - Tag: AsyncFetcher
class AsyncFetcher {
    // MARK: Types

    /// A serial `OperationQueue` to lock access to the `fetchQueue` and `completionHandlers` properties.
    private let serialAccessQueue = OperationQueue()

    /// An `OperationQueue` that contains `AsyncFetcherOperation`s for requested data.
    private let fetchQueue = OperationQueue()

    /// A dictionary of arrays of closures to call when an object has been fetched for an id.
    private var completionHandlers = [UUID: [(DisplayData?) -> Void]]()

    /// An `NSCache` used to store fetched objects.
    private var cache = NSCache<NSUUID, DisplayData>()

    // MARK: Initialization

    init() {
        serialAccessQueue.maxConcurrentOperationCount = 1
    }

    // MARK: Object fetching

    /**
     Asynchronously fetches data for a specified `UUID`.
     
     - Parameters:
         - identifier: The `UUID` to fetch data for.
         - completion: An optional called when the data has been fetched.
    */
    func fetchAsync(_ identifier: UUID, completion: ((DisplayData?) -> Void)? = nil) {
        // Use the serial queue while we access the fetch queue and completion handlers.
        serialAccessQueue.addOperation {
            // If a completion block has been provided, store it.
            if let completion = completion {
                let handlers = self.completionHandlers[identifier, default: []]
                self.completionHandlers[identifier] = handlers + [completion]
            }
            
            self.fetchData(for: identifier)
        }
    }

    /**
     Returns the previously fetched data for a specified `UUID`.
     
     - Parameter identifier: The `UUID` of the object to return.
     - Returns: The 'DisplayData' that has previously been fetched or nil.
     */
    func fetchedData(for identifier: UUID) -> DisplayData? {
        return cache.object(forKey: identifier as NSUUID)
    }

    /**
     Cancels any enqueued asychronous fetches for a specified `UUID`. Completion
     handlers are not called if a fetch is canceled.
     
     - Parameter identifier: The `UUID` to cancel fetches for.
     */
    func cancelFetch(_ identifier: UUID) {
        serialAccessQueue.addOperation {
            self.fetchQueue.isSuspended = true
            defer {
                self.fetchQueue.isSuspended = false
            }

            self.operation(for: identifier)?.cancel()
            self.completionHandlers[identifier] = nil
        }
    }

    // MARK: Convenience
    
    /**
     Begins fetching data for the provided `identifier` invoking the associated
     completion handler when complete.
     
     - Parameter identifier: The `UUID` to fetch data for.
     */
    private func fetchData(for identifier: UUID) {
        // If a request has already been made for the object, do nothing more.
        guard operation(for: identifier) == nil else { return }
        
        if let data = fetchedData(for: identifier) {
            // The object has already been cached; call the completion handler with that object.
            invokeCompletionHandlers(for: identifier, with: data)
        } else {
            // Enqueue a request for the object.
            let operation = AsyncFetcherOperation(identifier: identifier)
            
            // Set the operation's completion block to cache the fetched object and call the associated completion blocks.
            operation.completionBlock = { [weak operation] in
                guard let fetchedData = operation?.fetchedData else { return }
                self.cache.setObject(fetchedData, forKey: identifier as NSUUID)
                
                self.serialAccessQueue.addOperation {
                    self.invokeCompletionHandlers(for: identifier, with: fetchedData)
                }
            }
            
            fetchQueue.addOperation(operation)
        }
    }

    /**
     Returns any enqueued `ObjectFetcherOperation` for a specified `UUID`.
     
     - Parameter identifier: The `UUID` of the operation to return.
     - Returns: The enqueued `ObjectFetcherOperation` or nil.
     */
    private func operation(for identifier: UUID) -> AsyncFetcherOperation? {
        for case let fetchOperation as AsyncFetcherOperation in fetchQueue.operations
            where !fetchOperation.isCancelled && fetchOperation.identifier == identifier {
            return fetchOperation
        }
        
        return nil
    }

    /**
     Invokes any completion handlers for a specified `UUID`. Once called,
     the stored array of completion handlers for the `UUID` is cleared.
     
     - Parameters:
     - identifier: The `UUID` of the completion handlers to call.
     - object: The fetched object to pass when calling a completion handler.
     */
    private func invokeCompletionHandlers(for identifier: UUID, with fetchedData: DisplayData) {
        let completionHandlers = self.completionHandlers[identifier, default: []]
        self.completionHandlers[identifier] = nil

        for completionHandler in completionHandlers {
            completionHandler(fetchedData)
        }
    }
}
