/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Movie model holds metadata about movies and is used to build content items for the Top Shelf.
*/

import Foundation

/// A struct that represents the metadata for a single movie.
struct Movie: Codable {
    private enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case title
        case releaseDate = "releasedAt"
        case summary
        case genre
        case duration
        case mediaFormats
        case featuredActors
        case featuredDirectors
        case imageName
        case previewVideoName
    }

    enum MediaFormat: String, Codable {
        case videoResolutionHD = "hd"
        case videoResolution4K = "4k"
        case videoColorSpaceHDR = "hdr"
        case videoColorSpaceDolbyVision = "dolby-vision"
        case audioDolbyAtmos = "dolby-atmos"
        case audioTranscriptionClosedCaptioning = "cc"
        case audioTranscriptionSDH = "sdh"
        case audioDescription = "ad"
    }

    /// The movie's unique identifier.
    var identifier: String

    /// The movie's title.
    var title: String

    /// The date the movie was released.
    var releaseDate: Date

    /// A brief summary of the movie.
    var summary: String

    /// The movie's genre.
    var genre: String

    /// The length of the movie in seconds.
    var duration: TimeInterval

    /// A set of media formats supported by the movie.
    var mediaFormats: Set<MediaFormat>?

    /// A list of the movie's featured actors.
    var featuredActors: [String]?

    /// A list of the movie's featured directors.
    var featuredDirectors: [String]?

    /// The name of the movie's iage.
    ///
    /// In a real world application this should point to a resource on a back end service.
    var imageName: String
    
    /// The name of the movie's trailer.
    ///
    /// In a real world application this should point to a resource on a back end service.
    var previewVideoName: String

    /// Create an image URL by adding `scale` to the receiver's `imageName`.
    func imageURL(withScale scale: Int) -> URL? {
        precondition(scale > 0)

        /// In a real world application this should return a unique URL for each display scale to optimize network and disk usage.
        return Bundle.main.url(forResource: imageName, withExtension: "jpg")
    }

    /// Create a preview video URL from the receiver's `previewVideoName`.
    var previewVideoURL: URL? {
        return Bundle.main.url(forResource: previewVideoName, withExtension: "mp4")
    }
}
