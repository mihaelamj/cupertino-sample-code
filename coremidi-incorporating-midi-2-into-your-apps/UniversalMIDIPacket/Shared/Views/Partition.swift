/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A MIDI profile row view.
*/

import SwiftUI

struct Partition: View {

    var body: some View {
        HStack(alignment: .top) {
            Divider()
            .padding(.horizontal, UIConstants.defaultMargin / 2.0)
        }
    }
    
}

struct Partition_Previews: PreviewProvider {
    static var previews: some View {
        Partition()
    }
}
