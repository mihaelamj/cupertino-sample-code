/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A set of extensions, a class, and a function that simulate data coming from a server.
*/

import Foundation
import CoreData

// Simulates a remote server by generating randomized ServerEntry results
class MockServer: Server {
    private let queue = DispatchQueue(label: "MockServerQueue")

    enum DownloadError: Error {
        case cancelled
    }

    private class MockDownloadTask: DownloadTask {
        var isCancelled = false
        let onCancelled: () -> Void
        let queue: DispatchQueue

        init(delay: TimeInterval, queue: DispatchQueue, onSuccess: @escaping () -> Void, onCancelled: @escaping () -> Void) {
            self.onCancelled = onCancelled
            self.queue = queue

            queue.asyncAfter(deadline: .now() + delay) {
                if !self.isCancelled {
                    onSuccess()
                }
            }
        }

        func cancel() {
            queue.async {
                guard !self.isCancelled else { return }

                self.isCancelled = true
                self.onCancelled()
            }
        }
    }

    func fetchEntries(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> DownloadTask {
        let now = Date()

        let entries = generateFakeEntries(from: startDate, to: now)

        return MockDownloadTask(delay: Double.random(in: 0..<2.5), queue: queue, onSuccess: {
            completion(.success(entries))
        }, onCancelled: {
            completion(.failure(DownloadError.cancelled))
        })
    }
}

extension PersistentContainer {
    // Fills the Core Data store with initial fake data
    // If onlyIfNeeded is true, only does so if the store is empty
    func loadInitialData(onlyIfNeeded: Bool = true) {
        let context = newBackgroundContext()
        context.perform {
            do {
                let allEntriesRequest: NSFetchRequest<NSFetchRequestResult> = FeedEntry.fetchRequest()
                if !onlyIfNeeded {
                    // Delete all data currently in the store
                    let deleteAllRequest = NSBatchDeleteRequest(fetchRequest: allEntriesRequest)
                    deleteAllRequest.resultType = .resultTypeObjectIDs
                    let result = try context.execute(deleteAllRequest) as? NSBatchDeleteResult
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: result?.result as Any],
                                                        into: [self.viewContext])
                }
                if try !onlyIfNeeded || context.count(for: allEntriesRequest) == 0 {
                    let now = Date()
                    let start = now - (7 * 24 * 60 * 60)
                    let end = now - (60 * 60)
                    
                    _ = generateFakeEntries(from: start, to: end).map { FeedEntry(context: context, serverEntry: $0) }
                    try context.save()
                    
                    self.lastCleaned = nil
                }
            } catch {
                print("Could not load initial data due to \(error)")
            }
        }
    }
}

extension ServerEntry.Color {
    static func makeRandom() -> ServerEntry.Color {
        let randomRed = Double.random(in: 0...1)
        let randomBlue = Double.random(in: 0...1)
        let randomGreen = Double.random(in: 0...1)
        
        return ServerEntry.Color(red: randomRed, blue: randomBlue, green: randomGreen)
    }
}

extension ServerEntry {
    static func makeRandom(timestamp: Date) -> ServerEntry {
        return ServerEntry(timestamp: timestamp,
                           firstColor: Color.makeRandom(),
                           secondColor: Color.makeRandom(),
                           gradientDirection: Double.random(in: 0..<360))
    }
}

private func generateFakeEntries(from startDate: Date,
                                 to endDate: Date,
                                 interval: TimeInterval = 60 * 10,
                                 variation: TimeInterval = 5 * 60) -> [ServerEntry] {
    var entries = [ServerEntry]()
    for time in stride(from: startDate.timeIntervalSince1970, to: endDate.timeIntervalSince1970, by: interval) {
        let randomVariation = Double.random(in: -(variation)...(variation))
        let fakeTime = max(startDate.timeIntervalSince1970, min(time + randomVariation, endDate.timeIntervalSince1970))
        entries.append(ServerEntry.makeRandom(timestamp: Date(timeIntervalSince1970: fakeTime)))
    }
    return entries
}
