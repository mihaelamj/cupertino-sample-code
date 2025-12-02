/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that represents the external representation of a WWDC session hosted by the BAManifestURL.
*/

import Foundation

struct WWDC {
    enum Year: UInt, Equatable, CaseIterable, CustomStringConvertible, Codable {
        var description: String {
            guard let numeric = self.numericRepresentation else {
                return "WWDC"
            }
            
            return "WWDC\(numeric)"
        }
        
        fileprivate var numericRepresentation: UInt? {
            guard self != .unknown else {
                return nil
            }
            
            return self.rawValue
        }
        
        case unknown
        case fifteen = 15
        case nineteen = 19
        case twenty = 20
        case twentyOne = 21
        case twentyTwo = 22
        case twentyThree = 23
    }
}

class Session: Codable {
    let sessionId: Int
    let title: String
    let description: String
    let fileSize: UInt
    let authors: [String]
    let year: WWDC.Year
    let thumbnailOffsetInSeconds: Float
    let essential: Bool
    let URL: URL
    
    init(sessionId: Int,
         title: String,
         description: String,
         fileSize: UInt,
         authors: [String],
         year: WWDC.Year,
         thumbnailOffsetInSeconds: Float,
         essential: Bool,
         URL: URL) {
        
        self.sessionId = sessionId
        self.title = title
        self.description = description
        self.fileSize = fileSize
        self.authors = authors
        self.year = year
        self.thumbnailOffsetInSeconds = thumbnailOffsetInSeconds
        self.essential = essential
        self.URL = URL
    }
}

extension Session: Hashable {
    static func == (lhs: Session, rhs: Session) -> Bool {
        return lhs.sessionId == rhs.sessionId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.sessionId)
    }
}
