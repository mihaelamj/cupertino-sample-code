/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The App Intents extension entry point.
*/
import OSLog
import AppIntents

@main
struct ExampleAppIntentsExtension: AppIntentsExtension {
    init() {
        AppDependencyManager.shared.add(dependency: Repository.shared)
        let subsystem = Bundle.main.bundleIdentifier!
        let logger = Logger(subsystem: subsystem, category: "Example-Chat-App-AppIntents-Extension")
        logger.debug("Example Chat App AppIntents Extension launched")
    }
}
