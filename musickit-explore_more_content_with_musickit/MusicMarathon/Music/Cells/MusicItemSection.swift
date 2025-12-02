/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays the selected music item.
*/

import MusicKit
import SwiftUI

/// A cell that displays multiple music items.
struct MusicItemSection<MusicItemType, Content>: View where MusicItemType: MusicItem & Decodable & Equatable & Identifiable, Content: View {
    
    // MARK: - Initialization
    
    init(title: String, items: MusicItemCollection<MusicItemType>, content: @escaping (MusicItemType) -> Content) {
        self.title = title
        self.items = items
        self.content = content
    }
    
    init(fallbackTitle: String, items: MusicItemCollection<MusicItemType>, content: @escaping (MusicItemType) -> Content) {
        self.title = (items.title ?? fallbackTitle)
        self.items = items
        self.content = content
    }
    
    // MARK: - Properties
    
    private let title: String
    private let items: MusicItemCollection<MusicItemType>
    private let content: (MusicItemType) -> Content
    
    // MARK: - View
    
    var body: some View {
        Section(header: Text(title)) {
            ForEach(items, content: content)
            if items.hasNextBatch {
                additionalContentButton
            }
        }
    }
    
    private var additionalContentButton: some View {
        NavigationLink("See All", destination: AdditionalContentView<MusicItemType>(items: items, title: title))
    }
    
}
