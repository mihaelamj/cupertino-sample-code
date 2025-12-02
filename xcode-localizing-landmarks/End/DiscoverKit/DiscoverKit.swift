/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A placeholder view for the Discover feature of Landmarks.
*/

import Foundation
import SwiftUI

struct DiscoverFeedView: View {
    var body: some View {
        NavigationStack {
            // More content later, placeholder for now…
            Text(.Discover.feedTitle(newPosts: 42))
        }
        .navigationTitle(.Discover.title)
        .navigationSubtitle(.Discover.subtitle(friendsPosts: 5, curatedPosts: 9))
    }
}

/// Source of content in the Discover feed.
public enum ContentSource {
    /// A friend posted this.
    case friend
    /// The post comes from a curated list.
    case curated

    /// Localized description of the post's content source.
    public var localizedTitle: String {
        switch self {
        case .friend: String(localized: .Discover.sharedByFriends)
        case .curated: String(localized: .Discover.curatedCollection)
        }
    }
}

