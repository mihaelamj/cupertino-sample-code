/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Functions that implement the commands the SampleLaunchAgent understands.
*/

import Foundation
import ServiceManagement
import XPCOverlay

class Commands {
	class func register() {
		let service = SMAppService.agent(plistName: "com.xpc.example.agent.plist")

		do {
			try service.register()
			print("Successfully registered \(service)")
		} catch {
			print("Unable to register \(error)")
			exit(1)
		}
	}

	class func unregister() {
		let service = SMAppService.agent(plistName: "com.xpc.example.agent.plist")

		do {
			try service.unregister()
			print("Successfully unregistered \(service)")
		} catch {
			print("Unable to unregister \(error)")
			exit(1)
		}
	}

	class func status() {
		let service = SMAppService.agent(plistName: "com.xpc.example.agent.plist")

		print("\(service) has status \(service.status)")
    }
	
	class func test(withMessage message: String) {
		let request = xpc_dictionary_create_empty()
		message.withCString { rawMessage in
			xpc_dictionary_set_string(request, "MessageKey", rawMessage)
		}

		var error: xpc_rich_error_t? = nil
		let session = xpc_session_create_mach_service("com.xpc.example.agent.hello", nil, .none, &error)
		if let error = error {
			print("Unable to create xpc_session \(error)")
			exit(1)
		}

		let reply = xpc_session_send_message_with_reply_sync(session!, request, &error)
		if let error = error {
			print("Error sending message \(error)")
			exit(1)
		}

		let response = xpc_dictionary_get_string(reply!, "ResponseKey")
		let encodedResponse = String(cString: response!)

		print("Received \"\(encodedResponse)\"")

		xpc_session_cancel(session!)
	}
}
