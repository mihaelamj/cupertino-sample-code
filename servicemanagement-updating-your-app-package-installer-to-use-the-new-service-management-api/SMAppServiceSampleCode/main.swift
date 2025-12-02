/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sample CLI tool app that demonstrates how to package an SMAppService with a non-GUI app.
*/

/**
 * This is a sample CLI tool app that demonstrates how to package.
 *
 *
 * Usage: Run the main executable with an additional command argument:
 * ./SMAppServiceSample.app/Contents/MacOS/SMAppServiceSample COMMAND
 *
 * Commands:
 * register
 *  Registers the SampleLaunchAgent.
 * unregister
 *  Unregisters the SampleLaunchAgent.
 * status
 *  Indicates if the SampleLaunchAgent is allowed to run or not.
 * test <message>
 *  Sends an XPC message to the SampleLaunchAgent and displays the reply.
 *
 * */

import Foundation

if CommandLine.arguments.count <= 1 {
	print("USAGE: \(CommandLine.arguments[0]) [register|unregister|status|test]")
	exit(1)
}

let command = CommandLine.arguments[1]

if command == "register" {
	Commands.register()
} else if command == "unregister" {
	Commands.unregister()
} else if command == "status" {
	Commands.status()
} else if command == "test" {
	let message = CommandLine.arguments.count >= 3 ? CommandLine.arguments[2] : "World"
	Commands.test(withMessage: message)
} else {
	print("Unknown Command: \(command)")
	exit(1)
}
