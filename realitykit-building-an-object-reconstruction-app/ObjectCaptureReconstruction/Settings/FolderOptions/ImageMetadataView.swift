/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Show a green photo badge icon for available gravity and depth in the image folder.
*/

import SwiftUI

struct ImageMetadataView: View {
    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "photo.badge.checkmark")
                .foregroundColor(.green)
                .frame(height: 15)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showInfo) {
            VStack(alignment: .leading) {
                Text("Image Metadata Found")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 7)

                Divider()

                Text("Depth and Gravity Vector included in dataset.")
                    .padding([.horizontal, .bottom])
            }
            .font(.callout)
            .frame(width: 250)
        }
    }
}
