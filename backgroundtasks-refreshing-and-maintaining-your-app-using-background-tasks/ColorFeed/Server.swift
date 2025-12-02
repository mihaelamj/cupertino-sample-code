/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A set of protocols and a struct that represent an interface to a remote server.
*/

import Foundation

protocol Server {
    // Fetch any entries on the server that are more recent than the start date.
    @discardableResult
    func fetchEntries(since startDate: Date, completion: @escaping (Result<[ServerEntry], Error>) -> Void) -> DownloadTask
}

// A cancellable download task.
protocol DownloadTask {
    func cancel()
    var isCancelled: Bool { get }
}

// A struct representing the response from the server for a single feed entry.
struct ServerEntry: Codable {
    struct Color: Codable {
        var red: Double
        var blue: Double
        var green: Double
    }

    let timestamp: Date
    let firstColor: Color
    let secondColor: Color
    let gradientDirection: Double
}

