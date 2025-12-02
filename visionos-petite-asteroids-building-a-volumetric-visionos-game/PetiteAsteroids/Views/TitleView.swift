/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The title view for the startup screen and high-score view.
*/

import SwiftUI

struct TitleView: View {
    @Environment(AppModel.self) private var appModel
    let title: String

    let buttonWidth = 48.0
    let padding = 16.0
    var isDismissButtonVisible = true

    var body: some View {
        titleView
            .frame(minHeight: buttonWidth + padding * 2)
            .overlay {
                VStack {
                    HStack {
                        if isDismissButtonVisible {
                            dismissButton
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                }
            }
    }

    var dismissButton: some View {
        Button {
            appModel.menuVisibility = .hidden
        } label: {
            Image(systemName: "xmark")
                .font(.system(.title, design: .rounded))
                .foregroundStyle(.black.opacity(0.7))
                .frame(width: buttonWidth, height: buttonWidth)
        }
        .buttonStyle(.plain)
        .background(.gray.opacity(0.7))
        .clipShape(Circle())
        .contentShape(.hoverEffect, .circle)
        .hoverEffect(.highlight)
        .padding(padding)
    }

    @ViewBuilder
    var titleView: some View {
        ViewThatFits {
            Group {
                // Center the title in the view if it doesn't interfere with the button.
                Text(title)
                    .padding(.horizontal, padding + buttonWidth + padding)

                // Otherwise, use all available space minus the leading button width.
                Text(title)
                    .padding(.leading, buttonWidth)
                    .padding(.horizontal, padding * 2)
            }
            .multilineTextAlignment(.center)
            .font(.system(.extraLargeTitle, design: .rounded))
            .lineLimit(2)
            .padding(.vertical, padding)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    TitleView(title: "PETITE ASTEROIDS")
        .environment(AppModel())
}
