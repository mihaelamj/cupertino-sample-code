/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The simulation view containing the simulation scene, the buttons to start and stop networking, and the paired devices list.
*/

import SwiftUI
import SpriteKit
import OSLog

struct SimulationView: View {
    private let mode: SimulationEngine.Mode

    var scene = SimulationScene()
    @State private var engine: SimulationEngine
    @State private var networkTask: Task<Void, Error>?
    @State private var showAlert = false

    init(_ mode: SimulationEngine.Mode) {
        self.mode = mode
        self.engine = .init(mode)
    }

    var body: some View {
        GeometryReader { geoReader in
            VStack {
                ZStack(alignment: .top) {
                    SpriteView(scene: scene, debugOptions: [.showsFPS])

                    let state = engine.networkState
                    Button {
                        if state == .host(.publishing) || state == .viewer(.browsing) {
                            logger.info("Cancel Network Task")
                            networkTask?.cancel()
                            networkTask = nil
                        } else {
                            guard state != .viewer(.connecting) else { return }
                            logger.info("Start Network Task")
                            networkTask = engine.run()
                        }
                    } label: {
                        HStack {
                            let buttonImage = Image(systemName: "dot.radiowaves.left.and.right")
                            if state == .host(.publishing) || state == .viewer(.browsing) || state == .viewer(.connecting) {
                                buttonImage.symbolEffect(.variableColor.cumulative.dimInactiveLayers.reversing, options: .repeat(.continuous))
                            } else {
                                buttonImage.symbolEffectsRemoved()
                            }

                            Text(state.description)
                        }
                        .glassEffectButton()
                    }
                    .tint(state.color)
                    .disabled(state == .viewer(.connected))
                    .overlayButton()
                    .padding(.bottom)
                }
                .onChange(of: engine.showError) { _, newValue in
                    showAlert = newValue
                }
                .alert(isPresented: $showAlert, error: engine.wifiAwareError) { _ in
                    Button("OK") {
                        engine.showError = false
                    }
                } message: { error in
                    Text(error.recoverySuggestion ?? "Try again later.")
                }

                ZStack {
                    PairedDevicesView(engine: engine)

                    DeviceDiscoveryPairingView(mode: mode)
                        .overlayButton()
                }
                .frame(height: 0.15 * geoReader.size.height)
            }
            .task {
                let minDimension = min(geoReader.size.width, geoReader.size.height)
                scene.size = .init(width: minDimension, height: minDimension)
                scene.scaleMode = .aspectFill

                engine.setup(with: scene)
            }
        }
    }
}

struct OverlayButtonViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            Spacer()
            HStack {
                content
                Spacer()
            }
            .padding(.leading)
        }
    }
}

struct GlaffEffectViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .fontWeight(.bold)
            .glassEffect(.regular.interactive())
    }
}

extension View {
    func overlayButton() -> some View {
        modifier(OverlayButtonViewModifier())
    }

    func glassEffectButton() -> some View {
        modifier(GlaffEffectViewModifier())
    }
}
