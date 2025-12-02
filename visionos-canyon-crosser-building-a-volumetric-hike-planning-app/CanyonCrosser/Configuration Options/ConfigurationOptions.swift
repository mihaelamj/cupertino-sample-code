/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows configuration options for the app.
*/

import SwiftUI

struct ConfigurationOptions: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Configuration")
                .font(.largeTitle)
                .frame(maxWidth: .infinity)

            Divider()

            VStack {
                ScrollView {
                    BreakthroughEffectEditor()
                    TimelineViewEditor()
                    CloudsEditor()
                }
            }
        }
        .padding()
        .glassBackgroundEffect()
    }
}
