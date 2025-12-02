/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The map annotation data model.
*/

import OSLog
import Foundation

@MainActor
@Observable class MapAnnotationData {
    var annotations: [MapAnnotation]
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "MapAnnotationData")
    
    init() {
        self.annotations = []
        Task {
            await fetchAnnotations()
        }
    }
    
    /// Fetches all map annotations saved in the JSON file.
    func fetchAnnotations() async {
        guard let url = Bundle.main.url(forResource: "MapData", withExtension: "json") else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            annotations = try JSONDecoder().decode([MapAnnotation].self, from: data)
        } catch {
            logger.error("Fetching map annotation data failed: \(error)")
        }
    }
}
