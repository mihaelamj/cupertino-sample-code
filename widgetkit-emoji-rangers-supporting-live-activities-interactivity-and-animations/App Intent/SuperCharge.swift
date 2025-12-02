/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The supercharger App Intent.
*/

import Foundation
import AppIntents
import WidgetKit

#if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)

struct SuperCharge: AppIntent, ControlConfigurationIntent {
    
    static var title: LocalizedStringResource = "Emoji Ranger SuperCharger"
    static var description = IntentDescription("All heroes get instant 100% health.")
    
    func perform() async throws -> some IntentResult {
        EmojiRanger.superchargeHeros()
        return .result()
    }
}

#endif
