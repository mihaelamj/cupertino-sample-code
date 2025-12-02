/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manifest containing a listing of sessions available for download.
*/

import Foundation

final class Manifest: Codable {
    public let sessions: [LocalSession]
    private let sessionsByDownloadIdentifier: [String: LocalSession]
    
    static func load(from fileURL: URL) throws -> Manifest {
        let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        let decoder = PropertyListDecoder()
        return try decoder.decode(Manifest.self, from: data)
    }
    
    convenience init() {
        self.init(sessions: [])
    }
    
    init(sessions: [LocalSession]) {
        self.sessions = sessions
        self.sessionsByDownloadIdentifier = Dictionary(uniqueKeysWithValues: sessions.map { ($0.downloadIdentifier, $0) })
    }
    
    func session(for downloadIdentifier: String) -> LocalSession? {
        self.sessionsByDownloadIdentifier[downloadIdentifier]
    }
    
    func save(to fileURL: URL) throws {
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(self)
        try data.write(to: fileURL, options: .atomic)
    }
    
    // MARK: Codable
    
    private enum CodingKeys: String, CodingKey {
        case sessions
    }
    
    convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sessions = try container.decode([Session].self, forKey: .sessions)
        
        self.init(sessions: sessions.map {
            LocalSession(session: $0)
        })
    }
}
