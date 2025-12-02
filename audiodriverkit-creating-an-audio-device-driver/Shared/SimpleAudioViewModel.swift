/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model that indicates the state of driver-loading.
*/

import Foundation
import os.log
#if os(macOS)
import SystemExtensions
#endif

class SimpleAudioDriverLoadingStateMachine {

	enum State {
		case unloaded
		case activating
		case needsApproval
		case activated
		case activationError
	}

	enum Event {
		case activationStarted
		case promptForApproval
		case activationFinished
		case activationFailed
	}

	static func process(_ state: State, _ event: Event) -> State {

		switch state {
		case .unloaded:
			switch event {
			case .activationStarted:
				return .activating
			case .promptForApproval, .activationFinished, .activationFailed:
				return .activationError
			}

		case .activating, .needsApproval:
			switch event {
			case .activationStarted:
				return .activating
			case .promptForApproval:
				return .needsApproval
			case .activationFinished:
				return .activated
			case .activationFailed:
				return .activationError
			}

		case .activated:
			switch event {
			case .activationStarted:
				return .activating
			case .promptForApproval, .activationFailed:
				return .activationError
			case .activationFinished:
				return .activated
			}

		case .activationError:
			switch event {
			case .activationStarted:
				return .activating
			case .promptForApproval, .activationFinished, .activationFailed:
				return .activationError
			}
		}
	}
}

class SimpleAudioViewModel: NSObject {

	// Your dext may not start in unloaded state every time. Add logic or states to check this.
	@Published private var state: SimpleAudioDriverLoadingStateMachine.State = .unloaded

	private let dextIdentifier: String = Bundle.main.bundleIdentifier! + ".Driver"

	public var dextLoadingState: String {
		switch state {
		case .unloaded:
			return "SimpleAudioDriver isn't loaded."
		case .activating:
			return "Activating SimpleAudioDriver, please wait."
		case .needsApproval:
			return "Please follow the prompt to approve SimpleAudioDriver."
		case .activated:
			return "SimpleAudioDriver has been activated and is ready to use."
		case .activationError:
			return "SimpleAudioDriver has experienced an error during activation.\nPlease check the logs to find the error."
		}
	}
}

extension SimpleAudioViewModel: ObservableObject {

}

extension SimpleAudioViewModel {

#if os(macOS)
	func activateMyDext() {
		activateExtension(dextIdentifier)
	}

	/// - Tag: ActivateExtension
	func activateExtension(_ dextIdentifier: String) {

		let request = OSSystemExtensionRequest
			.activationRequest(forExtensionWithIdentifier: dextIdentifier,
							   queue: .main)
		request.delegate = self
		OSSystemExtensionManager.shared.submitRequest(request)

		self.state = SimpleAudioDriverLoadingStateMachine.process(self.state, .activationStarted)
	}
	
	// The sample doesn't use this method, but provides it for completeness.
	func deactivateExtension(_ dextIdentifier: String) {

		let request = OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier: dextIdentifier, queue: .main)
		request.delegate = self
		OSSystemExtensionManager.shared.submitRequest(request)

		// Update your state machine with deactivation states and process that change here
	}
#endif
}

#if os(macOS)
extension SimpleAudioViewModel: OSSystemExtensionRequestDelegate {

	func request(
		_ request: OSSystemExtensionRequest,
		actionForReplacingExtension existing: OSSystemExtensionProperties,
		withExtension ext: OSSystemExtensionProperties) -> OSSystemExtensionRequest.ReplacementAction {

		var replacementAction: OSSystemExtensionRequest.ReplacementAction

		os_log("sysex actionForReplacingExtension: %@ %@", existing, ext)

		// Add appropriate logic here to determine whether to replace the extension
		// with the new extension. Common things to check for include
		// testing whether the new extension's version number is newer than
		// the current version number, or whether the bundleIdentifier is different.
		// For simplicity, this sample always replaces the current extension
		// with the new one.
		replacementAction = .replace

		// The upgrade case may require a separate set of states.
		self.state = SimpleAudioDriverLoadingStateMachine.process(self.state, .activationStarted)

		return replacementAction
	}

	func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {

		os_log("sysex requestNeedsUserApproval")

		self.state = SimpleAudioDriverLoadingStateMachine.process(self.state, .promptForApproval)
	}

	func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {

		os_log("sysex didFinishWithResult: %d", result.rawValue)

		// The "result" may be "willCompleteAfterReboot", which requires another state.
		// This sample ignores this state for simplicity, but a production app needs to check for it.

		self.state = SimpleAudioDriverLoadingStateMachine.process(self.state, .activationFinished)
	}

	func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {

		os_log("sysex didFailWithError: %@", error.localizedDescription)

		// Some possible errors to check for:
		// Error 4: The dext identifier string in the code needs to match the one in the project settings.
		// Error 8: Indicates a signing problem. During development, set signing to "automatic" and "sign to run locally".
		// See README.md for more information.

		// This app only logs errors. Production apps need to provide feedback to customers about any errors they encounter while loading the dext.

		self.state = SimpleAudioDriverLoadingStateMachine.process(self.state, .activationFailed)
	}
}
#endif
