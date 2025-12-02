/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main extension entry point.
*/

import Intents

class Extension: INExtension {

    let intentHandlers: [IntentHandler] = [
        StartWorkoutIntentHandler(),
        PauseWorkoutIntentHandler(),
        ResumeWorkoutIntentHandler(),
        CancelWorkoutIntentHandler(),
        EndWorkoutIntentHandler()
    ]

    // MARK: INIntentHandlerProviding

    /// - Tag: HandlerForIntent
    override func handler(for intent: INIntent) -> Any {
        for handler in intentHandlers where handler.canHandle(intent) {
            return handler
        }
        preconditionFailure("Unexpected intent type")
    }
}
