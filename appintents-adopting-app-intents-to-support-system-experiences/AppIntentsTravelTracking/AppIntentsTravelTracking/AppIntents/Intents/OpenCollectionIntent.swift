/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent to open a collection.
*/

import AppIntents

struct OpenCollectionIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Collection"

    @Parameter(title: "Collection")
    var target: CollectionEntity

    /**
     If your app intent conforms to the `OpenIntent` protocol and the intent's only
     functionality is to open the app to a specific scene,
     you don't have to implement your own perform() method in your iOS, iPadOS, or Mac app you built with Mac Catalyst.
     */
    #if os(macOS)
    @Dependency var navigator: Navigator
    @Dependency var modelData: ModelData

    @MainActor
    func perform() async throws -> some IntentResult {

        if let collection = modelData.collection(id: target.id) {
            await navigator.navigate(to: collection)
        }

        return .result()
    }
    #endif
}

#if os(iOS)
extension OpenCollectionIntent: TargetContentProvidingIntent {}
#endif
