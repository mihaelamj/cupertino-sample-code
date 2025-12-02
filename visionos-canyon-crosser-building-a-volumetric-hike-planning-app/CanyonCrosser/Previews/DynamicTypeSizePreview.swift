/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Generic view to use dynamic type in Previews.
*/

import SwiftUI

struct DynamicTypeSizePreview<Content: View>: View {
    @ViewBuilder
    let content: Content

    var body: some View {
        HStack(spacing: 20) {
            VStack {
                content
                    .environment(\.dynamicTypeSize, .xSmall)

                Text("xSmall").padding().glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 10))
            }

            VStack {
                content
                    .environment(\.dynamicTypeSize, .large)

                Text("Large").padding().glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 10))
            }

            VStack {
                content
                    .environment(\.dynamicTypeSize, .xxxLarge)

                Text("xxxLarge").padding().glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
