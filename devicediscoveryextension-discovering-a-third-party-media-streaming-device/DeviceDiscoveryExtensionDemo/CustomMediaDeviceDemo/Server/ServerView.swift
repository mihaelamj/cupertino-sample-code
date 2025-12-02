/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main server UI view.
*/

import SwiftUI
import AVKit
import os

enum RoomLocation: String, CaseIterable, Identifiable {
	case livingRoom, kitchen, bedroom, garage, studyRoom
	var id: Self { self }

	func toString() -> String {
		return rawValue.replacingOccurrences(of: "([A-Z0-9])",
											 with: " $1",
											 options: .regularExpression)
		.capitalized
	}

}

enum TargetProtocol: String, CaseIterable, Identifiable {
	case ladybug, bolt
	var id: Self { self }
	func toString() -> String {
		return rawValue.capitalized
	}
}

enum BroadcastType: String, CaseIterable, Identifiable {
	case bluetoothAndBonjour, bonjour, bluetooth
	var id: Self { self }
	func toString() -> String {
		return rawValue.replacingOccurrences(of: "([A-Z0-9])",
											 with: " $1",
											 options: .regularExpression)
		.capitalized
	}
}

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

struct ServerView: View {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "ServerView")
	@ObservedObject var btPeripheralManager: BTPeripheralManager
	@ObservedObject var bonjourServer: BonjourServer

	@StateObject var viewModel = VideoViewModel()

    @State var isAdvertising = false
	@State private var selectedRoom: RoomLocation = .kitchen
	@State private var selectedProtocol: TargetProtocol = .ladybug
	@State private var selectedBroacasting: BroadcastType = .bluetoothAndBonjour

	init() {
		btPeripheralManager = BTPeripheralManager()
		bonjourServer = BonjourServer()
	}

	func advertiseButtonTapped() {
		isAdvertising.toggle()
		updateAdvertising()
	}

	func updateAdvertising() {
		if isAdvertising {
			if selectedBroacasting != .bonjour {
				btPeripheralManager.startAdvertising()
			}
			if selectedBroacasting != .bluetooth {
				try? bonjourServer.activate(name: selectedRoom.toString(), withProtocol: selectedProtocol.toString())
				bonjourServer.updateServerStateHandler = serverUpdated
			}
			logger.log("Started \(selectedBroacasting.toString()) Advertising")
		} else {
			if selectedBroacasting != .bonjour {
				btPeripheralManager.stopAdvertising()
			}
			if selectedBroacasting != .bluetooth {
				bonjourServer.invalidate()
			}
			logger.log("Stopped \(selectedBroacasting.toString()) Advertising")
		}
	}

	var body: some View {
		VStack {
			Spacer()
			Text("Media Device Discovery Demo Server")
				.font(.title)
				.bold()
				.fixedSize(horizontal: false, vertical: true)
				.multilineTextAlignment(.center)

			VideoPlayer(player: viewModel.player)

				.onAppear {
					viewModel.urlString = viewModel.testUrl
					logger.log("Video player started with \(viewModel.urlString ?? "Unkown" )")
				}
				.frame(height: 320) // This works fairly better than scaledToFit() on a Mac.

			List {
				if isAdvertising {
					HStack {
						Text("Location:")
						Text(selectedRoom.toString())
					}
					HStack {
						Text("Protocol:")
						Text(selectedProtocol.toString())
					}
					HStack {
						Text("Broadcast:")
						Text(selectedBroacasting.toString())
					}
				} else {
					Picker("Location", selection: $selectedRoom) {
						ForEach(RoomLocation.allCases) { room in
							Text(room.toString())
						}
					}
					.pickerStyle(.menu)

					Picker("Protocol", selection: $selectedProtocol) {
						ForEach(TargetProtocol.allCases) { proto in
							Text(proto.toString())
						}
					}
					.pickerStyle(.menu)

					Picker("Broadcast", selection: $selectedBroacasting) {
						ForEach(BroadcastType.allCases) { broadcasting in
							Text(broadcasting.toString())
						}
					}
					.pickerStyle(.menu)

				}
			}
			#if !os(macOS)
			.listStyle(.insetGrouped)
			.frame(minWidth: nil, idealWidth: nil, maxWidth: nil, minHeight: 160, idealHeight: 160, maxHeight: 160, alignment: .center)
			#endif

			VStack {
				Button {
					advertiseButtonTapped()
				} label: {
					isAdvertising ? Text("Stop \(selectedBroacasting.toString()) Advertising") : Text("Start \(selectedBroacasting.toString()) Advertising")
				}
				.roundedButton(foregroundColor: .white, backgroundColor: isAdvertising ? .red : .blue)
				.onChange(of: bonjourServer.isRunning) { running in
					if running != isAdvertising {
						isAdvertising = running
						updateAdvertising()
					}
				}
			}

			Spacer()
		}
		.scaledToFit()
	}

	func serverUpdated(_ state: DemoServerStatus) {
		viewModel.isPlaying = state.state.playing
		if viewModel.urlString == nil {
            // Retry in case the URL assignment failed previously.
			viewModel.urlString = viewModel.testUrl
		}
	}
}

struct RoundedButtonStyle: ButtonStyle {
  var foregroundColor: Color
  var backgroundColor: Color

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .font(.headline)
      .padding([.leading, .trailing], 30)
      .padding([.top, .bottom], 15)

      .foregroundColor(foregroundColor)
      .background(backgroundColor)
      .cornerRadius(12)
  }
}

extension View {
  func roundedButton (
    foregroundColor: Color = .white,
    backgroundColor: Color = .blue
  ) -> some View {
    self.buttonStyle(
      RoundedButtonStyle(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor
      )
    )
  }
}

struct ServerView_Previews: PreviewProvider {
	static var previews: some View {
		ServerView()
	}
}
