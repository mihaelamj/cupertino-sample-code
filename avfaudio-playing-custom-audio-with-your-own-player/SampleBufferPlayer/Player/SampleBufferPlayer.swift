/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The `SampleBufferPlayer` class is the thread-safe public interface to the player.
*/

import AVFoundation

@Observable class SampleBufferPlayer {
    
    // The `Playlist` structure contains the items in the current playlist,
    // and the index of the current item (if any).

    // You must access all members of this type under the protection of
    // the atomicity semaphore.

    // The player is in a stopped state whenever there is no current index.
    // The current index is always valid (and within the range of the items array)
    // when the state is in a paused state or playing.
    private struct Playlist {
        
        // Items in the playlist.
        var items: [SampleBufferItem] = []
        
        // The current item index, or nil if the player is in a stopped state.
        var currentIndex: Int?
        
    }

    // Objects to use for thread safety.
    private let atomicitySemaphore = DispatchSemaphore(value: 1)
    
    // Private properties with accesses that must be atomic, with protection from the atomicity semaphore.
    private var playlist = Playlist()
    
    // The serialized playback logic that executes on the serialization queue.
    private var playbackSerializer: SampleBufferSerializer!
    
    /// Initializes a sample buffer player.
    init() {
        // Create a "serializer" object to manage playback.
        playbackSerializer = SampleBufferSerializer()
        
        // Configure the time formatter to show minutes and seconds.
        timeFormatter.allowedUnits = [.minute, .second]
        timeFormatter.zeroFormattingBehavior = .pad

        // Create observers for the notifications from the serializer.
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(forName: SampleBufferSerializer.currentOffsetDidChange,
                                       object: nil,
                                       queue: .main) { [unowned self] notification in
            // During scrubbing, the offset value represents the slider position.
            if !isDraggingOffset {
                offset = notification.object as? Double ?? 0
            }
        }
        
        notificationCenter.addObserver(forName: SampleBufferSerializer.currentItemDidChange,
                                       object: playbackSerializer,
                                       queue: .main) { [unowned self] _ in
            setCurrentItemIndex(playbackSerializer.currentItem?.uniqueID)
            updateCurrentItemInfo()
            updateCurrentPlaybackInfo()
        }
        
        notificationCenter.addObserver(forName: SampleBufferSerializer.playbackRateDidChange,
                                       object: playbackSerializer,
                                       queue: .main) { [unowned self] _ in
            updateCurrentPlaybackInfo()
        }
        
        // Observe AVAudioSession notifications.
        // Note that a real app might need to observe other AVAudioSession notifications, too,
        // especially if it needs to properlay handle playback interruptions when the app is in the background.
        notificationCenter.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                       object: nil,
                                       queue: .main) { [unowned self] _ in
            setUpAudioSession()
        }

        notificationCenter.addObserver(forName: AVAudioSession.renderingModeChangeNotification,
                                       object: nil,
                                       queue: .main) { [unowned self] notification in
            if let userInfo = notification.userInfo,
               let value = userInfo[AVAudioSessionRenderingModeNewRenderingModeKey] as? Int,
               let mode = AVAudioSession.RenderingMode(rawValue: value) {
                renderingMode = mode
            }
        }

        notificationCenter.addObserver(forName: AVAudioSession.spatialPlaybackCapabilitiesChangedNotification,
                                       object: nil,
                                       queue: nil) { [unowned self] notification in
            playbackSerializer.printLog(component: .player, message: "Spatial Playback Capabilities Changed Notification.")
        }
        
        notificationCenter.addObserver(forName: AVAudioSession.renderingCapabilitiesChangeNotification,
                                       object: nil,
                                       queue: nil) { [unowned self] notification in
            playbackSerializer.printLog(component: .player, message: "Rendering Capabilities Change Notification.")
        }
        
        // Configure the audio session initially.
        setUpAudioSession()
        
        // Start using the Now Playing info panel.
        RemoteCommandCenter.handleRemoteCommands(using: self)
    }
    
    // Create an initial playlist.
    func loadPlaylist() async {
        let melody = await loadItem(title: "Melody", artist: "AirPlay Too")
        let synth = await loadItem(title: "Synth", artist: "DJ AVF")
        let rhythm = await loadItem(title: "Rhythm", artist: "The Air Players")
        originalItems = [melody, synth, rhythm]
        restorePlaylist()
    }
    
    func restorePlaylist() {
        items = originalItems
    }
    
    // Locate the asset file for this item, if possible, otherwise, replace the placeholder with an error item.
    private func loadItem(title: String, artist: String, fileExtension: String = "m4a") async -> PlaylistItem {
        guard let url = Bundle.main.url(forResource: title, withExtension: fileExtension) else {
            let error = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError)
            return PlaylistItem(title: title, artist: artist, error: error)
        }
        
        do {
            let duration = try await AVURLAsset(url: url).load(.duration)
            return PlaylistItem(url: url, title: title, artist: artist, duration: duration)
        } catch {
            return PlaylistItem(title: title, artist: artist, error: error)
        }
    }
    
    // A helper method that configures the app's audio session.
    // Note that the `.longFormAudio` policy indicates that the app's audio output needs to use AirPlay 2 for playback.
    private func setUpAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
        } catch {
            print("Failed to set audio session route sharing policy: \(error)")
        }
    }
    
    /// The original playlist items for restoring the playlist after editing it.
    private var originalItems = [PlaylistItem]()
    
    /// The number of items in the current playlist.
    var itemCount: Int {
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        return playlist.items.count
    }
    
    /// The items in the current playlist.
    var items: [PlaylistItem] {
        get {
            atomicitySemaphore.wait()
            defer { atomicitySemaphore.signal() }
            return playlist.items.map { $0.playlistItem }
        }
        set {
            replaceItems(with: newValue)
        }
    }
    
    /// Return the specified item in the playlist.
    func item(at index: Int) -> PlaylistItem {
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        return playlist.items[index].playlistItem
    }
    
    /// 'true' if the playlist contains an item at the specified index.
    func containsItem(at index: Int) -> Bool {
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        return (0 ..< playlist.items.count).contains(index)
    }
    
    /// Replaces all of the items in the playlist.
    func replaceItems(with newItems: [PlaylistItem]) {
        playbackSerializer.printLog(component: .player, message: "replacing all items")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        // Replace the playlist items.
        playlist.items = newItems.map { playbackSerializer.sampleBufferItem(playlistItem: $0, fromOffset: .zero) }
        
        // If the player is in a paused state or playing, try to restart playback from the first item.
        let index = playlist.currentIndex != nil ? 0 : nil
        
        restartWithItems(fromIndex: index, atOffset: .zero)
    }
    
    /// Plays from the start of the specified item, and continues with the following items
    /// already in the playlist.
    func seekToItem(at index: Int) {
        playbackSerializer.printLog(component: .player, message: "seeking item at playlist#\(index)")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        // Start playback from the specified item.
        restartWithItems(fromIndex: index, atOffset: .zero)
    }
    
    /// Moves the current offset to the specified offset in the current item.
    func seekToOffset(_ offset: CMTime) {
        playbackSerializer.printLog(component: .player, message: "seeking offset +\(offset.seconds)")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        // Start playback at the specified offset.
        restartWithItems(fromIndex: playlist.currentIndex, atOffset: offset)
    }
    
    /// Replaces a single item in the playlist, without stopping the current item, if possible.
    func replaceItem(at index: Int, with newItem: PlaylistItem) {
        playbackSerializer.printLog(component: .player, message: "replacing item at playlist#\(index)")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        playlist.items[index] = playbackSerializer.sampleBufferItem(playlistItem: newItem, fromOffset: .zero)
        
        // If you're not replacing the current item, let it continue playing.
        if let currentIndex = playlist.currentIndex, currentIndex != index {
            continueWithCurrentItems()
        }
        
        // Otherwise, stop the current item before restarting with the replacement item.
        else {
            restartWithItems(fromIndex: index, atOffset: .zero)
        }
    }
    
    /// Removes a single item from the playlist without stopping the current item, if possible.
    @discardableResult
    func removeItem(at index: Int) -> PlaylistItem {
        playbackSerializer.printLog(component: .player, message: "removing item at playlist#\(index)")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }

        let oldItem = playlist.items.remove(at: index).playlistItem
        
        // Stop playing if there are no items left, or you remove the current item.
        guard !playlist.items.isEmpty else { stopCurrentItems(); return oldItem }
        guard let currentIndex = playlist.currentIndex, currentIndex != index else { stopCurrentItems(); return oldItem }
        
        // Adjust the current item to account for the removal.
        if index < currentIndex {
            playlist.currentIndex = currentIndex - 1
        }
        
        // Let the current item continue playing.
        continueWithCurrentItems()

        return oldItem
    }
    
    /// Inserts a single item into the playlist.
    func insertItem(_ newItem: PlaylistItem, at index: Int) {
        playbackSerializer.printLog(component: .player, message: "inserting item at playlist#\(index)")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }

        playlist.items.insert(playbackSerializer.sampleBufferItem(playlistItem: newItem, fromOffset: .zero), at: index)
        
        // Adjust the current index, if necessary.
        if let currentIndex = playlist.currentIndex, index <= currentIndex {
            playlist.currentIndex = currentIndex + 1
        }

        // Let the current item continue playing.
        continueWithCurrentItems()
    }
    
    /// Moves items within the playlist.
    /// Note that both source and destination indexes refer to the playlist before the move.
    func moveItems(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard let firstSource = source.first, firstSource != destination else { return }
        
        playbackSerializer.printLog(component: .player, message: "moving item at playlist#\(firstSource) to playlist#\(destination)")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        // Move the item.
        playlist.items.move(fromOffsets: source, toOffset: destination)
        
        // Adjust the current index, if necessary.
        guard let currentItem = playbackSerializer.currentItem else { stopCurrentItems(); return }
        
        playlist.currentIndex = playlist.items.firstIndex(where: { $0.uniqueID == currentItem.uniqueID })
        
        // Let the current item continue playing.
        continueWithCurrentItems()
    }
    
    // A helper method that stops the playback of the current item.
    private func stopCurrentItems() {
        playlist.currentIndex = nil
        playbackSerializer.stopQueue()
    }
    
    // A helper method that restarts playback from a specified time offset of the specified item.
    private func restartWithItems(fromIndex proposedIndex: Int?, atOffset offset: CMTime) {
        // Stop the player if there's no current item.
        guard let currentIndex = proposedIndex,
            (0 ..< playlist.items.count).contains(currentIndex) else { stopCurrentItems(); return }
        
        // Start playing the requested items.
        playlist.currentIndex = currentIndex
        let playbackItems = Array(playlist.items[currentIndex ..< playlist.items.count])
        
        playbackSerializer.restartQueue(with: playbackItems, atOffset: offset)
    }

    // A helper method that continues playback of the current item, if possible, and the following items.
    private func continueWithCurrentItems() {
        // Stop the player if there's nothing to play.
        guard let currentIndex = playlist.currentIndex else { stopCurrentItems(); return }

        // Continue playing with a list of items to play starting from the current item.
        let playbackItems = Array(playlist.items[currentIndex ..< playlist.items.count])
        
        playbackSerializer.continueQueue(with: playbackItems)
    }

    /// The index of the current item, if any.
    /// Note that a non-nil index indicates that the player is playing or in a paused state.
    var currentItemIndex: Int? {
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        return playlist.currentIndex
    }
    
    /// The current item, if any.
    /// Note that a non-nil item indicates that the player is playing or in a paused state.
    var currentItem: PlaylistItem? {
        get {
            atomicitySemaphore.wait()
            defer { atomicitySemaphore.signal() }
            
            guard let index = playlist.currentIndex else { return nil }
            
            return playlist.items[index].playlistItem
        }
        set {
            // Check for a valid playlist item.
            if let newValue, let index = items.firstIndex(of: newValue) {
                seekToItem(at: index)
                play()
            }
        }
    }
    
    /// The current offset of the current item, if any.
    var currentItemEndOffset: CMTime? {
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        guard let index = playlist.currentIndex else { return nil }
        
        return playlist.items[index].endOffset
    }
    
    // A helper method that sets the current item index.
    // Note that the sample buffer serializer uses this privately (from a closure).
    private func setCurrentItemIndex(_ uniqueID: UUID?) {
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        // Set the current item index to the item with the specified ID.
        if let index = playlist.items.firstIndex(where: { $0.uniqueID == uniqueID }) {
            playlist.currentIndex = index
            playbackSerializer.printLog(component: .player, message: "setting current item at playlist#\(index) of \(playlist.items.count)")
        }
        
        // Or set the current item index to nil if there is no current item.
        else {
            playlist.currentIndex = nil
            playbackSerializer.printLog(component: .player, message: "setting no current item")
        }
    }
    
    /// Pauses playback, if the player is playing.
    func pause() {
        playbackSerializer.printLog(component: .player, message: "pause requested")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        if playlist.currentIndex != nil, playbackSerializer.playbackRate != 0 {
            playbackSerializer.pauseQueue()
        }
    }
    
    /// Starts or resumes playback, if the player is in a stopped or paused state.
    func play() {
        playbackSerializer.printLog(component: .player, message: "play requested")
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        // If there is no current item, try to set a current item
        // before starting playback.
        if playlist.currentIndex == nil {
            restartWithItems(fromIndex: 0, atOffset: .zero)
            
            if playlist.currentIndex != nil {
                playbackSerializer.resumeQueue()
            }
        }
        
        // Otherwise, just make sure playback is in a paused state.
        else if playbackSerializer.playbackRate == 0 {
            playbackSerializer.resumeQueue()
        }
    }
    
    /// 'true' if the player is currently playing.
    var isPlaying: Bool {
        atomicitySemaphore.wait()
        defer { atomicitySemaphore.signal() }
        
        return playlist.currentIndex != nil && playbackSerializer.playbackRate != 0
    }
    
    /// Gets the current playback rate.
    // Note that this method doesn't need synchronization using the serialization queue.
    var rate: Float {
        return playbackSerializer.playbackRate
    }
    
    // The playback time of the current item.
    var offset = 0.0
    
    // 'true' when the user is dragging the time offset slider.
    var isDraggingOffset = false {
        didSet {
            if !isDraggingOffset {
                skip(to: TimeInterval(offset))
            }
        }
    }
    
    // The rendering mode. When not applicable, the rendering mode badge is hidden.
    var renderingMode = AVAudioSession.RenderingMode.notApplicable
    
    // A formatter to display the playback time.
    private let timeFormatter = DateComponentsFormatter()
}

extension SampleBufferPlayer: RemoteCommandHandler {
    // Performs the remote command.
    func performRemoteCommand(_ command: RemoteCommand) {
        switch command {
        case .pause:
            pause()
        case .play:
            play()
        case .nextTrack:
            nextTrack()
        case .previousTrack:
            previousTrack()
        case .skipForward(let distance):
            skip(by: distance)
        case .skipBackward(let distance):
            skip(by: -distance)
        case .changePlaybackPosition(let offset):
            skip(to: offset)
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // Skips to the previous track.
    func previousTrack() {
        skipToCurrentItem(offsetBy: -1)
    }
    
    // Skips to the next track.
    func nextTrack() {
        skipToCurrentItem(offsetBy: 1)
    }
    
    // A helper method that skips to a different playlist item.
    private func skipToCurrentItem(offsetBy offset: Int) {
        if let currentItemIndex, containsItem(at: currentItemIndex + offset) {
            seekToItem(at: currentItemIndex + offset)
        }
    }
    
    // A helper method that skips to a playlist item offset, making sure to update the Now Playing info.
    func skip(to offset: TimeInterval) {
        seekToOffset(CMTime(seconds: Double(offset), preferredTimescale: 1000))
        updateCurrentPlaybackInfo()
    }
    
    // A helper method that skips a specified distance in the current item, making sure to update the Now Playing info.
    private func skip(by distance: TimeInterval) {
        if let currentItemEndOffset {
            seekToOffset(currentItemEndOffset + CMTime(seconds: distance, preferredTimescale: 1000))
            updateCurrentPlaybackInfo()
        }
    }
    
    // Update the Now Playing info with the new item information.
    private func updateCurrentItemInfo() {
        NowPlayingCenter.handleItemChange(item: currentItem,
                                          index: currentItemIndex ?? 0,
                                          count: itemCount)
    }
    
    // A helper method that updates the Now Playing playback information.
    private func updateCurrentPlaybackInfo() {
        NowPlayingCenter.handlePlaybackChange(playing: isPlaying,
                                              rate: rate,
                                              position: currentItemEndOffset?.seconds ?? 0,
                                              duration: currentItem?.duration.seconds ?? 0)
    }
    
    func getOffsetText() -> String {
        if currentItem != nil, let string = timeFormatter.string(from: offset) {
            return string
        }
        
        return "--:--"
    }
    
    func getDurationText() -> String {
        if let currentItem, let string = timeFormatter.string(from: currentItem.duration.seconds) {
            return string
        }
        
        return "--:--"
    }
}
