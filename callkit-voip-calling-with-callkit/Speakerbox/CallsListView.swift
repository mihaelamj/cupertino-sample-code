/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The call list view.
*/

import SwiftUI

struct CallsListView: View {

    @EnvironmentObject var callsController: SpeakerboxCallManager

    var body: some View {
        List {
            ForEach(callsController.calls, id: \.uuid) { call in
                CallView(call: call)
            }
        }
    }

}
