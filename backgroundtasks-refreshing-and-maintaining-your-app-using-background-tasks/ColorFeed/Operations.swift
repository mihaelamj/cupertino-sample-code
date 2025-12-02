/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of classes, extensions, and functions for fetching, adding, and deleting feed entries from the database.
*/

import Foundation
import CoreData

struct Operations {
    // Returns an array of operations for fetching the latest entries and then adding them to the Core Data store.
    static func getOperationsToFetchLatestEntries(using context: NSManagedObjectContext, server: Server) -> [Operation] {
        let fetchMostRecentEntry = FetchMostRecentEntryOperation(context: context)
        let downloadFromServer = DownloadEntriesFromServerOperation(context: context,
                                                                             server: server)
        let passTimestampToServer = BlockOperation { [unowned fetchMostRecentEntry, unowned downloadFromServer] in
            guard let timestamp = fetchMostRecentEntry.result?.timestamp else {
                downloadFromServer.cancel()
                return
            }
            downloadFromServer.sinceDate = timestamp
        }
        passTimestampToServer.addDependency(fetchMostRecentEntry)
        downloadFromServer.addDependency(passTimestampToServer)
        
        let addToStore = AddEntriesToStoreOperation(context: context)
        let passServerResultsToStore = BlockOperation { [unowned downloadFromServer, unowned addToStore] in
            guard case let .success(entries)? = downloadFromServer.result else {
                addToStore.cancel()
                return
            }
            addToStore.entries = entries
        }
        passServerResultsToStore.addDependency(downloadFromServer)
        addToStore.addDependency(passServerResultsToStore)
        
        return [fetchMostRecentEntry,
                passTimestampToServer,
                downloadFromServer,
                passServerResultsToStore,
                addToStore]
    }
}

// Fetches the most recent entry from the Core Data store.
class FetchMostRecentEntryOperation: Operation {
    private let context: NSManagedObjectContext
    
    var result: FeedEntry?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    override func main() {
        let request: NSFetchRequest<FeedEntry> = FeedEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeedEntry.timestamp), ascending: false)]
        request.fetchLimit = 1
        
        context.performAndWait {
            do {
                let fetchResult = try context.fetch(request)
                guard !fetchResult.isEmpty else { return }
                
                result = fetchResult[0]
            } catch {
                print("Error fetching from context: \(error)")
            }
        }
    }
}

// Downloads entries created after the specified date.
class DownloadEntriesFromServerOperation: Operation {
    enum OperationError: Error {
        case cancelled
    }

    private let context: NSManagedObjectContext
    private let server: Server
    var sinceDate: Date?
    
    var result: Result<[ServerEntry], Error>?
    
    private var downloading = false
    private var currentDownloadTask: DownloadTask?
    
    init(context: NSManagedObjectContext, server: Server) {
        self.context = context
        self.server = server
    }
    
    convenience init(context: NSManagedObjectContext, server: Server, sinceDate: Date?) {
        self.init(context: context, server: server)
        self.sinceDate = sinceDate
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isExecuting: Bool {
        return downloading
    }
    
    override var isFinished: Bool {
        return result != nil
    }
    
    override func cancel() {
        super.cancel()
        if let currentDownloadTask = currentDownloadTask {
            currentDownloadTask.cancel()
        }
    }
    
    func finish(result: Result<[ServerEntry], Error>) {
        guard downloading else { return }
        
        willChangeValue(forKey: #keyPath(isExecuting))
        willChangeValue(forKey: #keyPath(isFinished))
        
        downloading = false
        self.result = result
        currentDownloadTask = nil
        
        didChangeValue(forKey: #keyPath(isFinished))
        didChangeValue(forKey: #keyPath(isExecuting))
    }

    override func start() {
        willChangeValue(forKey: #keyPath(isExecuting))
        downloading = true
        didChangeValue(forKey: #keyPath(isExecuting))
        
        guard !isCancelled, let sinceDate = sinceDate else {
            finish(result: .failure(OperationError.cancelled))
            return
        }
        
        currentDownloadTask = server.fetchEntries(since: sinceDate, completion: finish)
    }
}

// An extension to create a Color object from the server representation of a color.
extension Color {
    convenience init(_ color: ServerEntry.Color) {
        self.init(red: color.red, green: color.green, blue: color.blue)
    }
}

// An extension to create a FeedEntry object from the server representation of an entry.
extension FeedEntry {
    convenience init(context: NSManagedObjectContext, serverEntry: ServerEntry) {
        self.init(context: context)
        self.firstColor = Color(serverEntry.firstColor)
        self.secondColor = Color(serverEntry.secondColor)
        self.gradientDirection = serverEntry.gradientDirection
        self.timestamp = serverEntry.timestamp
    }
}

// Add entries returned from the server to the Core Data store.
class AddEntriesToStoreOperation: Operation {
    private let context: NSManagedObjectContext
    var entries: [ServerEntry]?
    var delay: TimeInterval = 1

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    convenience init(context: NSManagedObjectContext, entries: [ServerEntry], delay: TimeInterval? = nil) {
        self.init(context: context)
        self.entries = entries
        if let delay = delay {
            self.delay = delay
        }
    }
    
    override func main() {
        guard let entries = entries else { return }

        context.performAndWait {
            do {
                for entry in entries {
                    _ = FeedEntry(context: context, serverEntry: entry)
                    
                    print("Adding entry with timestamp: \(entry.timestamp)")
                    
                    // Simulate a slow process by sleeping
                    if delay > 0 {
                        Thread.sleep(forTimeInterval: delay)
                    }
                    try context.save()

                    if isCancelled {
                        break
                    }
                }
            } catch {
                print("Error adding entries to store: \(error)")
            }
        }
    }
}

// Delete feed entries that match the predicate parameter from the Core Data store.
class DeleteFeedEntriesOperation: Operation {
    private let context: NSManagedObjectContext
    var predicate: NSPredicate?
    var delay: TimeInterval = 0.0005
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    convenience init(context: NSManagedObjectContext, predicate: NSPredicate?, delay: TimeInterval? = nil) {
        self.init(context: context)
        self.predicate = predicate
        if let delay = delay {
            self.delay = delay
        }
    }
    
    override func main() {
        let fetchRequest: NSFetchRequest<FeedEntry> = FeedEntry.fetchRequest()
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeedEntry.timestamp), ascending: true)]
        
        context.performAndWait {
            do {
                let entriesToDelete = try context.fetch(fetchRequest)
                for entry in entriesToDelete {
                    print("Deleting entry with timestamp: \(entry.timestamp?.description ?? "(nil)")")
                    
                    context.delete(entry)
                    
                    // Simulate a slow process by sleeping.
                    if delay > 0 {
                        Thread.sleep(forTimeInterval: delay)
                    }

                    if isCancelled {
                        break
                    }
                }
                try context.save()
            } catch {
                print("Error deleting entries: \(error)")
            }
        }
    }
}
