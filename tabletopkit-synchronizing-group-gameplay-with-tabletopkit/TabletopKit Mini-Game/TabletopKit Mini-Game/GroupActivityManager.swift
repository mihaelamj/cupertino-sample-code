/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Start and coordinate with GroupActivities sessions.
*/
import GroupActivities
import SwiftUI
@preconcurrency import TabletopKit

struct Activity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .generic
        metadata.title = "TabletopKit Mini-Game"
        return metadata
    }
}

@MainActor
class GroupActivityManager: Observable {
    var tabletopGame: TabletopGame
    var sessionTask = Task<Void, Never> {}

    init(tabletopGame: TabletopGame) {
        self.tabletopGame = tabletopGame
        sessionTask = Task { @MainActor in
            for await session in Activity.sessions() {
                tabletopGame.coordinateWithSession(session)
            }
        }
    }

    @MainActor
    deinit {
        tabletopGame.detachNetworkCoordinator()
    }
}
