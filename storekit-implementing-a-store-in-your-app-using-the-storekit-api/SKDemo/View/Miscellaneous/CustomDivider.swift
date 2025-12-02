/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom divider.
*/

import SwiftUI

struct CustomDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dividerGray)
            .frame(height: 0.85)
            .frame(maxWidth: .infinity)
    }
}
