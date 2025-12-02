/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A generic view to ensure all sections in the configuration panel look alike.
*/

import SwiftUI

struct EditorSection<Content: View>: View {
    let title: Text

    @ViewBuilder
    let content: Content

    var body: some View {
        VStack {
            title
                .font(.headline)

            Divider()

            content
        }
        .padding()
    }
}
