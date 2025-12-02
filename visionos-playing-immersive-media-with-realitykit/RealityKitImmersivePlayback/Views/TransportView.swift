/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container for transport controls.
*/

import SwiftUI

struct TransportView: View {
    let isCloseButtonVisible: Bool

    @Environment(AppModel.self) private var appModel
    @Environment(PlayerModel.self) private var playerModel

    init(isCloseButtonVisible: Bool = false) {
        self.isCloseButtonVisible = isCloseButtonVisible
    }

    var body: some View {
        VStack {
            HStack {
                if isCloseButtonVisible {
                    closeButton
                }
                toggleImmersionButton
                playPauseButton
            }
            .padding()
            .glassBackgroundEffect(in: .capsule)

            waitingIndicator
        }
        .padding()
    }

    // MARK: Private behavior

    @ViewBuilder
    private func button(named systemImageName: String, action: @escaping @MainActor () -> Void) -> some View {
        Button {
            Task { @MainActor in
                action()
            }
        } label: {
            image(named: systemImageName)
                .padding()
        }
        .buttonBorderShape(.circle)
    }

    @ViewBuilder
    private var closeButton: some View {
        button(named: "chevron.backward") {
            playerModel.stop()
        }
    }

    @ViewBuilder
    private func image(
        named systemImageName: String,
        dimension: CGFloat = 24
    ) -> some View {
        Image(systemName: systemImageName)
            .resizable()
            .scaledToFit()
            .frame(width: dimension, height: dimension)
    }

    @ViewBuilder
    private var playPauseButton: some View {
        if let status = playerModel.timeControlStatus, status.isPaused {
            button(named: "play.fill") {
                playerModel.play()
            }
        } else {
            button(named: "pause.fill") {
                playerModel.pause()
            }
        }
    }

    @ViewBuilder
    private var toggleImmersionButton: some View {
        if let toggleSystemImageName = appModel.toggleSystemImageName {
            button(named: toggleSystemImageName) {
                appModel.toggleImmersion()
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var waitingIndicator: some View {
        let isWaiting = playerModel.timeControlStatus?.isWaitingToPlayAtSpecifiedRate ?? false
        image(named: "progress.indicator")
            .symbolEffect(.rotate)
            .transition(.opacity)
            .opacity(isWaiting ? 1 : 0)
    }
}
