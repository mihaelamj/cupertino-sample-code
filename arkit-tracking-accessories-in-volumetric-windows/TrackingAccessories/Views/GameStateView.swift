/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the current state of the game.
*/

import SwiftUI

struct GameStateView: View {
    @State private var model: AccessoryTrackingModel
    @State private var throwSpeedTracker: ThrowSpeedTracker
    
    let tryAgainHandler: () -> Void
    let toppleAllHandler: () -> Void
    
    init(model: AccessoryTrackingModel, throwSpeedTracker: ThrowSpeedTracker,
         tryAgainHandler: @escaping () -> Void, toppleAllHandler: @escaping () -> Void) {
        self.model = model
        self.throwSpeedTracker = throwSpeedTracker
        self.tryAgainHandler = tryAgainHandler
        self.toppleAllHandler = toppleAllHandler
    }

    var body: some View {
        VStack(spacing: 12) {
            if model.gameState == .controllersTooCloseToCanStack {
                Text("Hey - no cheating! Please throw from a greater distance.")
                    .font(.largeTitle)
            } else if model.gameState == .gameWon {
                Text("You won!")
                    .font(.largeTitle)
            } else if model.gameState == .gameLost {
                Text("You lost!")
                    .font(.largeTitle)
            }
            
            if model.gameState == .gameWon || model.gameState == .gameLost {
                HStack(spacing: 12) {
                    Button(action: {
                        tryAgainHandler()
                    }) {
                        Label("Try again", systemImage: "arrow.clockwise")
                    }
                    Button(action: {
                        toppleAllHandler()
                    }) {
                        Label("Topple them for me", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                    }
                }
            }
            
            Text("Cans Toppled: \(model.toppledCanCount)")
                .font(.title)
            Text("Throws Left: \(model.remainingThrows)")
                .font(.title)
            
            if let trackerText = throwSpeedTracker.renderedText {
                Text(trackerText)
            }
        }
        .padding(24)
    }
}
