/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ConfigurationAppIntent for BackyardVisitorsWidget.
*/

import WidgetKit
import AppIntents
import BackyardBirdsData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Backyard Visitors Widget")
    
    @Parameter(title: "BackyardID")
    var backyardID: String
}
