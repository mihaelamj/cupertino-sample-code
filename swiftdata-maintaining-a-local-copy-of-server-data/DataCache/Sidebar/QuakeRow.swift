/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A single row in the list of earthquakes.
*/

import SwiftUI

/// A single row in the list of earthquakes.
struct QuakeRow: View {
    var quake: Quake

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black)
                .frame(width: 60, height: 40)
                .overlay {
                    Text(quake.magnitudeString)
                        .font(.title)
                        .bold()
                        .foregroundStyle(quake.color)
                }

            VStack(alignment: .leading) {
                Text(quake.location.name)
                    .font(.headline)
                Text("\(quake.time.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ModelContainerPreview(PreviewSampleData.inMemoryContainer) {
        VStack {
            QuakeRow(quake: .xsmall)
            QuakeRow(quake: .small)
            QuakeRow(quake: .medium)
            QuakeRow(quake: .large)
            QuakeRow(quake: .xlarge)
        }
        .padding()
        .frame(minWidth: 300, alignment: .leading)
    }
}
