/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MoviesResponse model holds metadata about a list of movies.
*/

/// A struct that represents a collection of movies returned from a back end service.
struct MoviesResponse: Codable {

    /// The list of movies in the response.
    var movies: [Movie]
}
