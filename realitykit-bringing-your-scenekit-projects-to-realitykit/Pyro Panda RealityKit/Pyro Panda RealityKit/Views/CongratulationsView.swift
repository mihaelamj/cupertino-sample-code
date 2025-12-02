/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The congratulations UI.
*/

import SwiftUI

struct CongratulationsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var animate = false

    var body: some View {
        if appModel.levelFinished {
            GeometryReader { geometry in
                ZStack {
                    Image("Max")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.3)
                        .opacity(1)
                        .scaleEffect(animate ? 1 : 0.01)
                        .animation(.easeOut(duration: 1.0), value: animate)

                    Image("congrats")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.8)
                        .offset(y: geometry.size.height * 0.3)
                        .opacity(1)
                        .scaleEffect(animate ? 1 : 0.01)
                        .animation(.easeOut(duration: 1.0).delay(0.5), value: animate)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    animate = true
                }
            }
        }
    }
}
