/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper view to show an attribute that represents an UUID in a list.
*/

import SwiftUI

/// A helper view to show an attribute that represents an UUID in a list.
struct UUIDTextView: View {
    var attribute: String
    var uuid: String

    var body: some View {
        VStack {
            Text(attribute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
            Text(uuid)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(.secondary)
                .listRowSeparator(.hidden, edges: .top)
                .alignmentGuide(.listRowSeparatorLeading) { _ in
                    return 0
                }
        }
    }
}
