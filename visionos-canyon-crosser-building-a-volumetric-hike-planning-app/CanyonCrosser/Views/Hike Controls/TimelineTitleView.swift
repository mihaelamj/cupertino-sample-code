/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The title view for the timeline.
*/

import SwiftUI

struct TimelineTitleView: View {
    let title: String
    let sunriseTime: String
    let sunsetTime: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.headline)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "sunrise.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.yellow)

                    Text(sunriseTime)
                        .textCase(.lowercase)
                }
                .font(.caption.lowercaseSmallCaps())

                HStack(spacing: 4) {
                    Image(systemName: "sunset.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.yellow)

                    Text(sunsetTime)
                        .textCase(.lowercase)
                }
                .font(.caption.lowercaseSmallCaps())
            }
            .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DynamicTypeSizePreview {
        TimelineTitleView(
            title: MockData.brightAngel.name,
            sunriseTime: MockData.sunriseTime,
            sunsetTime: MockData.sunsetTime
        )
        .padding(40)
        .glassBackgroundEffect()
    }
}
