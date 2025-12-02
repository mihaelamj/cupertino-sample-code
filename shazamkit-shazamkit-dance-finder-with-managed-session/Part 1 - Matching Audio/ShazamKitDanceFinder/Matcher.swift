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

    private let session: SHSession
    private let audioEngine = AVAudioEngine()
    
    init() {
        
        if let catalog = try? ResourcesProvider.catalog() {
            session = SHSession(catalog: catalog)
        } else {
            session = SHSession()
        }
        
        configureAudioEngine()
    }
    
    func match() async {
        
        let granted = await AVAudioApplication.requestRecordPermission()
        
        guard granted else {
            print("No recording permission granted...")
            return
        }

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine")
            return
        }
        
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
    
    private func configureAudioEngine() {
        
        // Setup audio engine to receive audio buffers for matching.
        Task.detached { try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker]) }
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: .zero)
        inputNode.installTap(onBus: .zero, bufferSize: 8192, format: recordingFormat) { [weak self] (buffer, time) in
            self?.session.matchStreamingBuffer(buffer, at: time)
        }
        
        audioEngine.prepare()
    }
    
    func stopRecording() {
        
        guard audioEngine.isRunning else { return }
        audioEngine.stop()
    }
    
    func endSession() {
        
        // Reset result of any previous match.
        isMatching = false
        currentMatchResult = MatchResult(match: nil)
    }
}
