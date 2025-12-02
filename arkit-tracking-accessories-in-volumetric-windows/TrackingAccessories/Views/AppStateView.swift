/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the current state of the app model.
*/

import SwiftUI

struct AppStateView: View {
    @State private var model: AccessoryTrackingModel
    
    @State private var leftControllerBall: Ball
    @State private var rightControllerBall: Ball
    
    @State private var isVelocityVisualizationEnabled = false
    
    init(model: AccessoryTrackingModel, leftControllerBall: Ball, rightControllerBall: Ball, isVelocityVisualizationEnabled: Bool = false) {
        self.model = model
        self.leftControllerBall = leftControllerBall
        self.rightControllerBall = rightControllerBall
        self.isVelocityVisualizationEnabled = isVelocityVisualizationEnabled
    }
    
    var body: some View {
        VStack(spacing: 12) {
            switch model.state {
            case .startingUp:
                Text("Starting Up")
                    .font(.title)
                Text("Please wait...")
            case .accessoryTrackingNotAuthorized:
                Text("This app is missing necessary authorizations. You can change this in Settings > Privacy & Security.")
                    .font(.title)
            case .accessoryTrackingNotSupported:
                Text("This app requires functionality that isn’t supported in Simulator.")
            case .noControllerConnected:
                Text("Controller(s) Disconnected")
                    .font(.title)
                Image(systemName: "gamecontroller")
                Text("Please connect a controller to continue.")
            case .arkitSessionError:
                Text("An error occurred. Please restart the app.")
            case .allControllersOutOfBounds:
                Text("Out of Bounds")
                    .font(.title)
                Image(systemName: "rotate.3d")
                Text("Please hold a controller inside the volume.")
            case .noUsableController:
                Text("Controller Tracking Limited")
                    .font(.title)
                Image(systemName: "x.circle")
                Text("Please keep controllers in view.")
            case .inGame:
                Text("Try to topple all cans by throwing the ball!")
                    .font(.title)
            }
            Toggle("Show velocity on controller", isOn: $isVelocityVisualizationEnabled)
                .toggleStyle(.switch)
                .onChange(of: isVelocityVisualizationEnabled) { _, isEnabled in
                    leftControllerBall.velocityVisualization.isEnabled = isEnabled
                    rightControllerBall.velocityVisualization.isEnabled = isEnabled
                }
        }
        .padding(12)
    }
}
