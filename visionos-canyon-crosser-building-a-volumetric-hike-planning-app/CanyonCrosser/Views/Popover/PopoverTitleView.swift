/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The title view for the rest stop and trailhead popovers.
*/

import SwiftUI

struct PopoverTitleView: View {
    @Environment(\.dismiss) var dismissPopover
    let title: String

    let buttonWidth = 44.0
    let padding = 16.0

    var body: some View {
        titleView
            .frame(minHeight: buttonWidth + padding * 2)
            .overlay {
                VStack {
                    HStack {
                        dismissButton
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                }
            }
    }

    var dismissButton: some View {
        Button {
            dismissPopover()
        } label: {
            Image(systemName: "xmark")
                .foregroundColor(.secondary)
                .frame(width: buttonWidth, height: buttonWidth)
        }
        .buttonBorderShape(.circle)
        .padding(padding)
    }

    @ViewBuilder
    var titleView: some View {
        ViewThatFits {
            Group {
                // Center the title in view, if it doesn't interfere with the button.
                Text(title)
                    .padding(.horizontal, padding + buttonWidth + padding)

                // Otherwise, use all of the available space minus leading button.
                Text(title)
                    .padding(.leading, buttonWidth)
                    .padding(.horizontal, padding * 2)
            }
            .multilineTextAlignment(.center)
            .font(.title2)
            .lineLimit(2)
            .padding(.vertical, padding)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    DynamicTypeSizePreview {
        VStack(spacing: 20) {
            Group {
                PopoverTitleView(title: "Short Title")
                PopoverTitleView(title: MockData.brightAngel.name)
                PopoverTitleView(title: "A really really long title that needs multiple lines")
                PopoverTitleView(title: "A really really long title that needs multiple lines so we truncate it to just two lines")
            }
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 42))
        }
        .frame(width: 366.0)
    }
}
