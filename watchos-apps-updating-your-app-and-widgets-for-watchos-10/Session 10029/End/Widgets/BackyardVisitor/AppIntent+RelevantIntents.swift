/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Donations for BackyardVisitorsWidget using ConfigurationAppIntent.
*/

import WidgetKit
import AppIntents
import BackyardBirdsData
import SwiftData

func updateBackyardRelevantIntents() async {
    let modelContext = ModelContext(DataGeneration.container)
    var relevantIntents = [RelevantIntent]()
    
    for backyard in Backyard.allBackyards(modelContext: modelContext) {

        let configIntent = ConfigurationAppIntent()
        configIntent.backyardID = backyard.id.uuidString
        let relevantFoodDateContext = RelevantContext.date(from: backyard.lowSuppliesDate(for: .food), to: backyard.expectedEmptyDate(for: .food))
        let relevantFoodIntent = RelevantIntent(configIntent, widgetKind: "BackyardVisitorsWidget", relevance: relevantFoodDateContext)
        relevantIntents.append(relevantFoodIntent)

        let relevantWaterDateContext = RelevantContext.date(from: backyard.lowSuppliesDate(for: .water), to: backyard.expectedEmptyDate(for: .water))
        let relevantWaterIntent = RelevantIntent(configIntent, widgetKind: "BackyardVisitorsWidget", relevance: relevantWaterDateContext)
        relevantIntents.append(relevantWaterIntent)
    }

    do {
        try await RelevantIntentManager.shared.updateRelevantIntents(relevantIntents)
    } catch { }
}
