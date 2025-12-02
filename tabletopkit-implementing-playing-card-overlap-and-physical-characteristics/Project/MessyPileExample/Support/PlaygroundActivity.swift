/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A group activity definition for multiplayer.
*/

import GroupActivities

struct PlaygroundActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.type = .generic
        metadata.title = "Playground"
        return metadata
    }
}
