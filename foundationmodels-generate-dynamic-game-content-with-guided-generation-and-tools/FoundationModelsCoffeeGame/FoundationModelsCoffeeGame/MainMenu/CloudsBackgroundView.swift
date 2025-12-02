/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An animated background for the game loading screen that shows clouds floating by.
*/

import SwiftUI

#if os(iOS)
    import UIKit
#endif

private struct Cloud: Identifiable {
    let id = UUID()
    var yPosition: CGFloat
    var speed: Double
}

struct CloudsBackgroundView: View {
    @State private var cloudOffsets: [UUID: CGFloat] = [:]
    @State private var clouds: [Cloud] = []
    @State var screenWidth = 100.0  // default value
    @State var screenHeight = 1000.0  // default value

    let cloudCount = 4

    var body: some View {
        ZStack {
            ForEach(clouds) { cloud in
                Image("cloud1")
                    .interpolation(.none)
                    .position(
                        x: cloudOffsets[cloud.id, default: screenWidth + 100],
                        y: cloud.yPosition
                    )
                    .onAppear {
                        startCloudAnimation(for: cloud, isInitial: true)
                    }
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            if size.width > 0 {
                screenWidth = size.width
                screenHeight = size.height
                createClouds()
            }
        }
        .onAppear {
            createClouds()
        }
        .ignoresSafeArea()
    }

    private func createClouds() {
        clouds = (0..<cloudCount).map { _ in
            Cloud(
                yPosition: CGFloat.random(in: 50...screenHeight),
                speed: Double.random(in: 40.0..<50.0)
            )
        }

        for cloud in clouds {
            cloudOffsets[cloud.id] = CGFloat.random(in: 0..<screenWidth)
        }
    }

    private func startCloudAnimation(for cloud: Cloud, isInitial: Bool) {
        let startX = isInitial ? Double.random(in: 0..<300.0) : -150.0
        let endX = screenWidth + 150

        cloudOffsets[cloud.id] = startX

        withAnimation(.linear(duration: cloud.speed)) {
            cloudOffsets[cloud.id] = endX
        }

        Task { @MainActor in
            try await Task.sleep(for: .seconds(cloud.speed))
            if let index = clouds.firstIndex(where: { $0.id == cloud.id }) {
                clouds[index].yPosition = CGFloat.random(in: 50...screenHeight)
            }
            startCloudAnimation(for: cloud, isInitial: false)
        }
    }
}

#Preview {
    CloudsBackgroundView()
}
