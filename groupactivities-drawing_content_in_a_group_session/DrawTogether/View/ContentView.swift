/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary entry point for the app's user interface.
*/

import SwiftUI
import GroupActivities

struct ContentView: View {
    @StateObject var canvas = Canvas()

    var body: some View {
        VStack {
            HStack {
                Spacer()
                StrokeColorIndicator(color: canvas.strokeColor.uiColor)
            }
            .padding()

            ZStack {
                CanvasView(canvas: canvas)
                PhotoPlacementView(canvas: canvas)
            }

            ControlBar(canvas: canvas)
                .padding()

        }
        .task {
            for await session in DrawTogether.sessions() {
                canvas.configureGroupSession(session)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
