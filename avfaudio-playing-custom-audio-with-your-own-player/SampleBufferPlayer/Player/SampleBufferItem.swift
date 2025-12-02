/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The `SampleBufferItem` class represents one item in a list of items being played.
*/

import AVFoundation

class SampleBufferItem {
    
    // An identifier that uniquely identifies an item within a SampleBufferPlayer item list.
    // Note that this make it possible to distinguish between two `PlaylistItem` items in
    // the list, that are otherwise identical.
    let uniqueID: UUID
    
    // A shortened identifier for logging.
    let logID: String
    
    // The underlying media item that this sample buffer playlist item represents.
    let playlistItem: PlaylistItem
    
    // The offset time, relative to the underlying media item, at which this item starts playing.
    var startOffset: CMTime {
        didSet {
            endOffset = startOffset
        }
    }
    
    // The offset time, relative to the underlying media item, to present the
    // next sample from this item.
    // Note that the actual duration of samples from this item so far is
    // `endOffset - startOffset`.
    private(set) var endOffset: CMTime
    
    // 'true' if this item has been (or is being) used to get sample buffers.
    private(set) var isEnqueued = false
    
    // A boundary time observer for this item.
    var boundaryTimeObserver: Any?
    
    // A source of sample buffers for this item.
    private var sampleBufferSource: SampleBufferSource?
    
    // An error that the sample buffer source reports.
    private(set) var sampleBufferError: Error?
    
    // Private properties that support logging.
    private var sampleBufferLogCount = 0
    
    private var printLog: (SampleBufferSerializer.LogComponentType, String, CMTime?) -> Void
    
    // Creates a playlist item.
    init(playlistItem: PlaylistItem,
         fromOffset offset: CMTime,
         printLog: @escaping (SampleBufferSerializer.LogComponentType, String, CMTime?) -> Void) {
        
        self.uniqueID = UUID()
        self.logID = String(uniqueID.uuidString.suffix(4))
        self.playlistItem = playlistItem
        self.printLog = printLog
        
        self.startOffset = offset > .zero && offset < playlistItem.duration ? offset : .zero
        self.endOffset = startOffset
    }
    
    // Gets the next sample buffer for this item, or nil if no more are available.
    func nextSampleBuffer() -> CMSampleBuffer? {
        
        // No more sample buffers after an error.
        guard sampleBufferError == nil else { return nil }
        
        do {
            // Try to create a sample buffer source, if this is the first
            // time you're requesting a sample buffer.
            if sampleBufferSource == nil {
                isEnqueued = true
                sampleBufferSource = try SampleBufferSource(fileURL: playlistItem.url, fromOffset: startOffset)
                printLog(.enqueuer, "ID: \(logID) starting buffers at +", startOffset)
            }
            
            if sampleBufferLogCount > 0 {
                printLog(.enqueuer, "ID: \(logID) enqueuing buffer #\(sampleBufferLogCount) at +", endOffset)
            }
            
            sampleBufferLogCount += 1
            
            // Try to read from a sample buffer source.
            let source = sampleBufferSource!
            let sampleBuffer = try source.nextSampleBuffer()
            
            // Keep track of the actual duration of this source.
            endOffset = source.nextSampleOffset
            
            return sampleBuffer
        }
            
        // End-of-file is caught as a thrown error, along with actual errors
        // the system encounters when reading the source file.
        catch {
            printLog(.enqueuer, "ID: \(logID) stopped after \(sampleBufferLogCount) buffers (\(error)) +", endOffset)
            sampleBufferError = error
            return nil
        }
    }
    
    // Stops getting samples from the current source, if any.
    func flushSource() {
        isEnqueued = false
        sampleBufferSource = nil
        sampleBufferError = nil
        boundaryTimeObserver = nil
    }
    
    // Prevents the system from using the item to get more buffers.
    func invalidateSource() {
        sampleBufferSource = nil
        sampleBufferError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
    }
}
