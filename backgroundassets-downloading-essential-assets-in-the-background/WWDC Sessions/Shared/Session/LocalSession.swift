/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An on-disk representation of a Session.
*/

import Foundation
import SwiftUI
import AVFoundation
import OSLog

final class LocalSession: Session, ObservableObject, Identifiable, @unchecked Sendable {
    enum State: Decodable {
        case downloaded
        case remote
    }
    
    let id = UUID()
    
    var downloadIdentifier: String {
        "SESSION_ID_\(sessionId)"
    }
    
    let fileURL: URL
    
    @Published
    var thumbnailImage: CGImage? = nil {
        willSet {
            self.stateLock.lock()
        }
        didSet {
            self.stateLock.unlock()
        }
    }
    
    @Published
    var downloadProgress = 0.0 {
        willSet {
            self.stateLock.lock()
        }
        didSet {
            self.stateLock.unlock()
        }
    }
    
    @Published
    var state: State = .remote {
        willSet {
            self.stateLock.lock()
        }
        didSet {
            self.stateLock.unlock()
        }
    }
    
    private let stateLock = NSLock()
    
    convenience init(session: Session) {
        let fileURL = LocalSession.fileURL(for: session)
        let exists = FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false))
        let state: State = exists ? .downloaded : .remote
        
        self.init(fileURL: fileURL, session: session, state: state)
    }

    init(fileURL: URL, session: Session, state: State) {
        self.fileURL = fileURL
        self.state = state
        
        super.init(sessionId: session.sessionId,
                   title: session.title,
                   description: session.description,
                   fileSize: session.fileSize,
                   authors: session.authors,
                   year: session.year,
                   thumbnailOffsetInSeconds: session.thumbnailOffsetInSeconds,
                   essential: session.essential,
                   URL: session.URL)
        
        if self.state != .remote {
            Task {
                await fetchThumbnail()
            }
        }
    }
    
    @MainActor
    func fetchThumbnail() async {
        let image = await self.generateThumbnail()
        self.thumbnailImage = image
    }
    
    func generateThumbnail() async -> CGImage? {
        let asset = AVAsset(url: self.fileURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        let time = CMTime(seconds: Double(self.thumbnailOffsetInSeconds), preferredTimescale: 1)
        
        enum ImageGenerationError: Error {
            case noResult
        }
        
        return try? await withCheckedThrowingContinuation({ continuation in
            imageGenerator.generateCGImageAsynchronously(for: time) { image, time, error in
                if let image = image {
                    continuation.resume(returning: image)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: ImageGenerationError.noResult)
                }
            }
        })
    }
    
    public static func fileURL(for session: Session) -> URL {
        return SharedSettings.sessionStorageURL
            .appending(component: "Session_\(session.sessionId)")
            .appendingPathExtension("mp4")
    }
    
    // MARK: Decodable
    
    private enum CodingKeys: String, CodingKey {
        case fileURL
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fileURL = try container.decode(Foundation.URL.self, forKey: .fileURL)
        try super.init(from: decoder)
    }
}
