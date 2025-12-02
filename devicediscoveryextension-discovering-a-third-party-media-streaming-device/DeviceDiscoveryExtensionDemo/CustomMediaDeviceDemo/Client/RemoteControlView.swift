/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A client view that displays the UI to remotely control the streamed media's playback.
*/

import SwiftUI

struct RemoteControlView: View {

	@ObservedObject var remote: ClientSessionController

	init(withSession session: DemoClientSession) {
		remote = ClientSessionController(withClientSession: session)
	}

	var body: some View {
		VStack {
			Text("Remote Controls")
			HStack {
				Button { }
					label: {
						Image(systemName: remote.isPlaying ? "minus.circle.fill" : "minus.circle")
							.padding()
							.font(.largeTitle)
							.disabled(!remote.isPlaying)
				}
				Button { }
					label: {
						Image(systemName: remote.isPlaying ? "stop.circle.fill" : "stop.circle")
							.padding()
							.font(.largeTitle)
							.disabled(!remote.isPlaying)
				}
				Button {
					if !remote.isPlaying {
						remote.play()
					} else {
						remote.stop()
					}
				}
					label: {
						Image(systemName: remote.isPlaying ? "pause.circle.fill" : "play.circle.fill")
							.padding()
							.font(.largeTitle)
				}
				Button { }
					label: {
						Image(systemName: remote.isPlaying ? "plus.circle.fill" : "plus.circle")
							.padding()
							.font(.largeTitle)
							.foregroundColor(.accentColor)
							.disabled(!remote.isPlaying)
				}
			}
		}

	}
}

class ClientSessionController: ObservableObject {
	@Published var isPlaying = false

	let clientSession: DemoClientSession
	init(withClientSession session: DemoClientSession) {
		clientSession = session
		clientSession.serverUpdateHandler = serverUpdated
	}

	func serverUpdated(_ state: DemoServerStatus) {
		print("ClientSessionController::serverUpdated")
		isPlaying = state.state.playing
	}

	func play() {
		clientSession.sendPlay()
	}

	func stop() {
		clientSession.sendStop()
	}
}
