/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to get the crowd status of a landmark.
*/

import AppIntents
import SwiftUI

struct GetCrowdStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Crowd Status"

    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$landmark) Crowd Status")
    }

    @Parameter var landmark: LandmarkEntity

    @Dependency var modelData: ModelData

    #if os(macOS)
    @Dependency var navigator: Navigator
    #endif

    func perform() async throws -> some ReturnsValue<Int> & ProvidesDialog {

        guard await modelData.isOpen(landmark) else { /* Exit early... */
            return .result(value: 0, dialog: "\(landmark.name) is closed.")
        }

        if systemContext.currentMode.canContinueInForeground {
            do {
                try await continueInForeground(alwaysConfirm: false)
                #if os(iOS)
                // You don't need to add code here to open the app
                // and navigate to the scene that matches the intent.
                // Instead, LandmarksSplitView` uses `.onAppIntentExecution()` view modifiers
                // for navigation.
                #elseif os(macOS)
                await navigator.navigate(to: landmark)
                #endif
            } catch {
                // Open app denied.
            }
        }

        // Retrieve status and return dialog...

        let status = await modelData.getCrowdStatus(landmark)

        return .result(
            value: status,
            dialog: IntentDialog(getCrowdStatusDescription(for: status))
        )
    }
}

#if os(iOS)
extension GetCrowdStatusIntent: TargetContentProvidingIntent {}
#endif

extension GetCrowdStatusIntent {
    func getCrowdStatusDescription(for occupancyPercentage: Int) -> LocalizedStringResource {
        switch occupancyPercentage {
        case 0:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, it's closed."
        case 1...20:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, it's nearly empty."
        case 21...40:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, it's not very busy."
        case 41...60:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, it's moderately busy."
        case 61...80:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, it's quite busy."
        case 81...95:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, it's very busy."
        case 96...100:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, it's extremely busy."
        default:
            "\(landmark.name) is at \(occupancyPercentage)% capacity, which is an unexpected value."
        }
    }
}

extension GetCrowdStatusIntent: PredictableIntent {
    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: \.$landmark) { landmark in
            DisplayRepresentation(
                title: "Get \(landmark.name) crowd status",
                image: landmark.displayRepresentation.image
            )
        }
    }
}
