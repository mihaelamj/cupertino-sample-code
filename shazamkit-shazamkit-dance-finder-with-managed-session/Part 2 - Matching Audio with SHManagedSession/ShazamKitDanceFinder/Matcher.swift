/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model that handles audio recognition and updates SwiftUI Views with the result.
*/

import Foundation
import ShazamKit

struct MatchResult: Identifiable, Equatable {
    let id = UUID()
    let match: SHMatch?
}

@MainActor final class Matcher: ObservableObject {
    
    @Published var isMatching = false
    @Published var currentMatchResult: MatchResult?
    
    var currentMediaItem: SHMatchedMediaItem? {
        currentMatchResult?.match?.mediaItems.first
    }

    private let session: SHManagedSession
    
    init() {
        
        if let catalog = try? ResourcesProvider.catalog() {
            session = SHManagedSession(catalog: catalog)
        } else {
            session = SHManagedSession()
        }
    }
    
    func match() async {
        
        isMatching = true
        
        for await result in session.results {
            switch result {
            case .match(let match):
                Task { @MainActor in
                    self.currentMatchResult = MatchResult(match: match)
                }
            case .noMatch(_):
                print("No match")
                endSession()
            case .error(let error, _):
                print("Error \(error.localizedDescription)")
                endSession()
            }
            stopRecording()
        }
    }
    
    func stopRecording() {
        
        session.cancel()
    }
    
    func endSession() {
        
        // Reset result of any previous match.
        isMatching = false
        currentMatchResult = MatchResult(match: nil)
    }
}
