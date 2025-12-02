/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for the device-picker UI view.
*/

import SwiftUI
import AVRouting
import AVKit
import os

struct DevicePickerView: UIViewRepresentable {

	func makeUIView(context: Context) -> UIView {

		let routePickerView = AVRoutePickerView()

		routePickerView.delegate = context.coordinator
		routePickerView.customRoutingController = RouteManager.shared.customRoutingController
		routePickerView.backgroundColor = UIColor.white
		routePickerView.activeTintColor = UIColor.red
		routePickerView.tintColor = UIColor.black
		routePickerView.prioritizesVideoDevices = true

		return routePickerView
	}

	func updateUIView(_ uiView: UIView, context: Context) {
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	class Coordinator: NSObject, AVRoutePickerViewDelegate {

		func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
			if let type = UTType("com.example.apple-DataAccessDemo.menu") {
				let customRow1 = AVCustomRoutingActionItem()
				customRow1.type = type
				RouteManager.shared.customRoutingController?.customActionItems = [customRow1]
			}
		}
	}
}
