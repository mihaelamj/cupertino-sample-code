/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper view to show an attribute and its value on a single line.
*/

import SwiftUI

/// A helper view to show an attribute and its value on a single line.
struct AttributeValueTextView: View {
    var attribute: String
    var value: String
    
    var body: some View {
        HStack {
            Text(attribute)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
