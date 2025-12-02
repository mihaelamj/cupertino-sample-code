/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content provider responds to system requests for Top Shelf content.
*/

import TVServices

class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {

        // Work can be performed asychronously. The completion handler may be called on any queue.
        DispatchQueue.global().async {
            do {

                // Create a JSON decoder.
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .secondsSince1970

                // Load a simulated network response.
                guard let url = Bundle.main.url(forResource: "movies", withExtension: "json") else {
                    fatalError("Unable to load movies.json file.")
                }
                let data = try Data(contentsOf: url, options: [.alwaysMapped, .uncached])
                let response = try decoder.decode(MoviesResponse.self, from: data)

                // Reply with a content object.
                let items = response.movies.map { $0.makeCarouselItem() }
                let content = TVTopShelfCarouselContent(style: .details, items: items)
                completionHandler(content)
            } catch {
                
                // Call the completion handler with `nil` if content cannot be loaded at this time.
                completionHandler(nil)
            }
        }
    }
}

extension Movie {

    /// Make a carousel item that represents the movie.
    fileprivate func makeCarouselItem() -> TVTopShelfCarouselItem {
        let item = TVTopShelfCarouselItem(identifier: identifier)

        item.contextTitle = NSLocalizedString("Featured Movie", comment: "The context title for a movie item.")
        item.title = title
        item.summary = summary
        item.genre = genre
        item.duration = duration
        item.creationDate = releaseDate
        item.previewVideoURL = previewVideoURL
        item.mediaOptions = makeCarouselMediaOptions()
        item.namedAttributes = makeCarouselNamedAttributes()
        item.setImageURL(imageURL(withScale: 1), for: .screenScale1x)
        item.setImageURL(imageURL(withScale: 2), for: .screenScale2x)

        item.playAction = URL(string: "full-screen-top-shelf://movie/\(identifier)/play").map { TVTopShelfAction(url: $0) }
        item.displayAction = URL(string: "full-screen-top-shelf://movie/\(identifier)").map { TVTopShelfAction(url: $0) }

        return item
    }

    private func makeCarouselMediaOptions() -> TVTopShelfCarouselItem.MediaOptions {
        guard let mediaFormats = mediaFormats else {
            return TVTopShelfCarouselItem.MediaOptions()
        }

        return mediaFormats.reduce(into: TVTopShelfCarouselItem.MediaOptions()) { result, format in
            switch format {
            case .videoResolutionHD:
                result.formUnion(.videoResolutionHD)
            case .videoResolution4K:
                result.formUnion(.videoResolution4K)
            case .videoColorSpaceHDR:
                result.formUnion(.videoColorSpaceHDR)
            case .videoColorSpaceDolbyVision:
                result.formUnion(.videoColorSpaceDolbyVision)
            case .audioDolbyAtmos:
                result.formUnion(.audioDolbyAtmos)
            case .audioTranscriptionClosedCaptioning:
                result.formUnion(.audioTranscriptionClosedCaptioning)
            case .audioTranscriptionSDH:
                result.formUnion(.audioTranscriptionSDH)
            case .audioDescription:
                result.formUnion(.audioDescription)
            }
        }
    }

    private func makeCarouselNamedAttributes() -> [TVTopShelfNamedAttribute] {
        var namedAttributes = [TVTopShelfNamedAttribute]()

        if let values = featuredActors, !values.isEmpty {
            let name = String(format: NSLocalizedString("Actors", comment: "The attribute name for the actor role."), values.count)
            namedAttributes.append(TVTopShelfNamedAttribute(name: name, values: values))
        }

        if let values = featuredDirectors, !values.isEmpty {
            let name = String(format: NSLocalizedString("Directors", comment: "The attribute name for the director role."), values.count)
            namedAttributes.append(TVTopShelfNamedAttribute(name: name, values: values))
        }

        return namedAttributes
    }
}
