/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for the video UI.
*/

import SwiftUI
import Network
import os
import AVKit
import AVRouting

class VideoViewModel: ObservableObject {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "VideoViewModel")
	let testUrl = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"
	var player = AVPlayer()

	@Published var urlString: String? {
		didSet {
			guard let urlString = urlString, let url = URL(string: urlString) else {
				logger.error("Couldn't set url string")
				return
			}
			player.replaceCurrentItem(with: AVPlayerItem(url: url))
			player.seek(to: .zero)
		}
	}

	@Published var isPlaying = false {
		didSet {
			if isPlaying {
				player.play()
			} else {
				player.pause()
			}
		}
	}

}

struct ClientView: View {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "ClientView")

	let avRoutePub = NotificationCenter.default.publisher(for: .AVRouteDetectorMultipleRoutesDetectedDidChange)
		.receive(on: DispatchQueue.main)
	@State var routeDetected = false

	@State var customRowTapped: AVCustomRoutingActionItem?
	@State var didTapCustomRow = false

	@State var routeName = "Select route"
	@State var clientSession: DemoClientSession?
	@State var cachedEndpoint: NWEndpoint?
	@ObservedObject var directConnectionTester = ConnectionTester()
	@ObservedObject var endpointConnectionTester = ConnectionTester()
	@ObservedObject var routeManager = RouteManager.shared

	let directConnectionEndpoint = NWEndpoint.service(name: "DD demo server", type: "_deviceaccess._udp", domain: "local", interface: nil)

	// Needed for mocking the picker UI AirPlay grouping.
	@StateObject var viewModel = VideoViewModel()

	init() {
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, policy: .longFormVideo)
		} catch {
			logger.error("Setting category to AVAudioSessionCategoryPlayback failed.")
		}
	}

	var body: some View {
		VStack {
			VideoPlayer(player: viewModel.player)
				.onAppear {
					viewModel.urlString = viewModel.testUrl
					logger.log("Video player started with \(viewModel.urlString ?? "Unkown" )")
				}
				.frame(minWidth: 100, idealWidth: nil, maxWidth: nil, minHeight: 100, idealHeight: nil, maxHeight: 200, alignment: .center)

			Spacer()
			Text("Media Device Discovery Demo Client")
				.font(.title)
				.bold()
				.fixedSize(horizontal: false, vertical: true)
				.multilineTextAlignment(.center)

			Spacer()
			HStack {

				Text(routeName)
					.font(.title)
					.frame(maxWidth: .infinity, alignment: .center)
					.fixedSize()
					.padding(.leading)

				if routeDetected {
					DevicePickerView()
					.frame(width: 60, height: 60)
					.padding(.trailing)
				}
			}
			.alert(isPresented: $didTapCustomRow) {
				Alert(title: Text("Custom Row Was Tapped"),
					  message: Text("The row you tapped was\n{ \((customRowTapped != nil) ? customRowTapped!.title : "no title") }"),
					  dismissButton: Alert.Button.cancel(Text("Ok")) {
								self.didTapCustomRow = false
								self.customRowTapped = nil
							})
			}
			.onAppear(perform: {
				RouteManager.shared.onSessionUpdateHandler = didSessionUpdate
				RouteManager.shared.setupRouteDetector()
				routeDetected = RouteManager.shared.anyRouteDetected()
				if routeDetected {
					activateRouteManager()
				}
				logger.log("onAppear routesDetected: \(routeDetected)")
			})
			.onReceive(avRoutePub) { (_) in
				routeDetected = RouteManager.shared.anyRouteDetected()
				if routeDetected {
					activateRouteManager()
				} else {
					RouteManager.shared.deactivate()
				}
				logger.log("onReceive routesDetected: \(routeDetected)")
			}

			Spacer()

			if let session = clientSession {
				RemoteControlView(withSession: session)
				Spacer()
			}

		}
	}

	private func activateRouteManager() {
		RouteManager.shared.activate() { customRowTapped in
			print(customRowTapped)
			self.customRowTapped = customRowTapped
			self.didTapCustomRow = true
		}
	}

	func didSessionUpdate(_ session: DemoClientSession?, route: AVCustomDeviceRoute?) {
		logger.log("ClientView::didSessionUpdate: \(String(describing: session)), \(String(describing: route))")
		if session !== clientSession && clientSession != nil {
			// Disconnect a session if it's no longer active.
			clientSession?.stop()
		}
		clientSession = session

		var newRouteName = "DemoDevice"
		if let endpoint = route?.networkEndpoint {
			cachedEndpoint = .opaque(endpoint)
			if session != nil {
				let rawTxtRecord = cachedEndpoint?.txtRecord
				if let txtRecord = rawTxtRecord?.dictionary {
					if let name = txtRecord["NAME"] {
						newRouteName = name
					}
				}
			}
		}
		routeName = (session == nil) ? "Select route" : newRouteName
	}

}

class ConnectionTester: ObservableObject {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "ConnectionTester")
	@Published var connectionEstablished = false
	@Published var connectionFailed = false
	@Published var alertRequired = false

	func testDirectConnection(to nwEndpoint: NWEndpoint) {
		connectionEstablished = false
		connectionFailed = false
		
		let parameters = NWParameters.udp
		parameters.includePeerToPeer = true

		let newConnection = DemoUdpConnection(nwConnection: NWConnection(to: nwEndpoint, using: parameters))
		let newSession = DemoClientSession()
		newConnection.delegate = newSession

		newSession.stateUpdatedHandler = { (state: DemoSessionState) in
			switch state {
			case .connected:
				self.logger.log("Direct Route connection completed")
				newSession.stop()
				self.connectionEstablished = true
				self.alertRequired = true

			case .disconnected:
				self.logger.log("Direct Route session completed, removing.")
				self.connectionFailed = true
				self.alertRequired = true

			default:
				break
			}

		}
		newConnection.start()
	}
}

struct ClientView_Previews: PreviewProvider {
	static var previews: some View {
		ClientView()
	}
}

extension AVCustomRoutingActionItem {
	var title: String {
		guard let overrideTitle = self.overrideTitle else {
			return self.type.localizedDescription!
		}
		return overrideTitle
	}

}
