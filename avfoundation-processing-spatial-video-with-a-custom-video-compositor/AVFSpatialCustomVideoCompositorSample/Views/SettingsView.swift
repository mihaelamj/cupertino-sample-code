/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents a user interface to select the compositor to use for playback and export.
*/

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) private var dismiss
	@AppStorage("compositorType") private var compositorType = CompositorType.monoOut
	
	var body: some View {
		NavigationStack {
			Form {
				Picker("Compositor type", selection: $compositorType) {
					Text("Stereo compositor").tag(CompositorType.stereoOut)
					Text("Mono compositor").tag(CompositorType.monoOut)
					Text("No compositor").tag(CompositorType.none)
				}
			}
			.toolbar {
				Button("Done") {
					dismiss()
				}
			}
			.navigationTitle("Settings")
		}
	}
}
