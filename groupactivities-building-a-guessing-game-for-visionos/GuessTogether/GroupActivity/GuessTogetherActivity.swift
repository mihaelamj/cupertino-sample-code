/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the Guess Together app's group activity.
*/

import CoreTransferable
import GroupActivities

struct GuessTogetherActivity: GroupActivity, Transferable, Sendable {
    var metadata: GroupActivityMetadata = {
        var metadata = GroupActivityMetadata()
        metadata.title = "Guess Together"
        return metadata
    }()
}
