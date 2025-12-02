/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides the structure and functions that process the images based on the classification request.
*/

import Vision

struct ImageFile {
    // The local URL of the image.
    let url: URL
    let name: String
    // The dictionary that holds an image's classification identifier and confidence value.
    var observations: [String: Float] = [:]
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
    }
}

// Returns an `ImageFile` object based on the `ClassifyImageRequest` results.
func classifyImage(url: URL) async throws -> ImageFile {
    var image = ImageFile(url: url)
    
    // Vision request to classify an image.
    let request = ClassifyImageRequest()
    
    // Perform the request on the image, and return an array of `ClassificationObservation` objects.
    let results = try await request.perform(on: url)
        // Use `hasMinimumPrecision` for a high-recall filter.
        .filter { $0.hasMinimumPrecision(0.1, forRecall: 0.8) }
        // Use `hasMinimumRecall` for a high-precision filter.
        // .filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
    
    // Add each classification identifier and its respective confidence level into the observations dictionary.
    for classification in results {
        image.observations[classification.identifier] = classification.confidence
    }
    
    return image
}

// Processes all the selected images concurrently.
func classifyAllImages(urls: [URL]) async throws -> [ImageFile] {
    var images = [ImageFile]()
    
    try await withThrowingTaskGroup(of: ImageFile.self) { group in
        for url in urls {
            group.addTask {
                return try await classifyImage(url: url)
            }
        }
        
        for try await image in group {
            images.append(image)
        }
    }
    
    return images
}
