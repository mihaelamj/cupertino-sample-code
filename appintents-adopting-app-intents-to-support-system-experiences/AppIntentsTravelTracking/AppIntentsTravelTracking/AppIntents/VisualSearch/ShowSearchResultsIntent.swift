/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to continue the search experience in visual intelligence.
*/

#if canImport(VisualIntelligence)
import AppIntents
import VisualIntelligence

@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct ShowSearchResultsIntent {
    static let title: LocalizedStringResource = "Landmarks Image Search"

    var semanticContent: SemanticContentDescriptor
}

extension ShowSearchResultsIntent: TargetContentProvidingIntent {}
#endif
