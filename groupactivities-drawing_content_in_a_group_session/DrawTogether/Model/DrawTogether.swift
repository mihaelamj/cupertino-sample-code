/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The activity that users use to draw together.
*/

import Foundation
import GroupActivities

struct DrawTogether: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = NSLocalizedString("Draw Together", comment: "Title of group activity")
        metadata.type = .generic
        return metadata
    }
}
