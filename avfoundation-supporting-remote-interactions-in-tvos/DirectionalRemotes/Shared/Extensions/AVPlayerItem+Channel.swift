/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility to create a player item with a channel.
*/

import AVFoundation

extension AVPlayerItem {
    /// Creates a new instance with the specified channel. Uses the channel and current program
    /// properties to set up the metadata values for the item.
    ///
    /// If the list of programs for the specified channel is empty or the current program is `nil`, this
    /// initializer returns `nil`. For example:
    ///
    ///     let channel = Channel(title: "Title", programs: [])
    ///     let playerItem = AVPlayerItem(withChannel: channel)
    ///     print(playerItem)
    ///     // Prints "nil."
    ///
    /// - Parameter channel: The channel to use to create the player item.
    convenience init?(withChannel channel: Channel) {
        guard let currentProgram = channel.currentProgram else { return nil }
        
        self.init(url: currentProgram.playlistURL)

        self.externalMetadata = [
            createMetadataItem(.iTunesMetadataTrackSubTitle, value: channel.name),
            createMetadataItem(.commonIdentifierTitle, value: currentProgram.title),
            createMetadataItem(.commonIdentifierDescription, value: currentProgram.description)
            // Set any other metadata item applicable to your application.
        ]
    }

    /// Creates an instance of `AVMetadataItem` with the specified identifier and value.
    ///
    /// The `value` parameter needs to conform to both the `NSCopying` and `NSObjectProtocol`
    /// protocols.
    ///
    /// - Parameter identifier: The identifier for the new `AVMetadataItem`.
    /// - Parameter value: The value for the new `AVMetadataItem`.
    private func createMetadataItem(_ identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        // Specify "und" to indicate an undefined language.
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
}

