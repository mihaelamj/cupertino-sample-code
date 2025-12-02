/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view that provides the driver-loading UI.
*/

import SwiftUI

struct SimpleAudioView: View {
	@ObservedObject var viewModel = SimpleAudioViewModel()
	var userClient = SimpleAudioUserClient()
	@State var userClientText = ""

	var body: some View {
#if os(macOS)
		VStack(alignment: .center) {
			Text("Driver Manager")
				.padding()
				.font(.title)
			Text(self.viewModel.dextLoadingState)
				.multilineTextAlignment(.center)
			HStack {
				Button(
					action: {
						self.viewModel.activateMyDext()
					}, label: {
						Text("Install Dext")
					}
				)
			}
		}
		.frame(width: 500, height: 200, alignment: .center)
#endif
		VStack(alignment: .center) {
			Text("User Client Manager")
				.padding()
				.font(.title)
			Text(userClientText)
				.multilineTextAlignment(.center)
			HStack {
				Button(
					action: {
						userClientText = self.userClient.open()
					}, label: {
						Text("Open User Client")
					}
				)
				Spacer()
				Button(
					action: {
						userClientText = self.userClient.toggleRate()
					}, label: {
						Text("Toggle Sample Rate")
					}
				)
				Spacer()
				Button(
					action: {
						userClientText = self.userClient.toggleDataSource()
					}, label: {
						Text("Toggle Data Source")
					}
				)
			}
		}
		.frame(width: 500, height: 200, alignment: .center)
	}
}

struct SimpleAudioDriverView_Previews: PreviewProvider {
    static var previews: some View {
		SimpleAudioView()
    }
}
