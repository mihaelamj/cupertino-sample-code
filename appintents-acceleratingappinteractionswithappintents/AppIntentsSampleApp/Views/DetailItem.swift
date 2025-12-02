/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a label and a value.
*/

import SwiftUI

struct DetailItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.body)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
