# Interacting with nearby points of interest

Provide automatic search completions for a partial search query, search the map for relevant locations nearby, and retrieve details for selected points of interest.

## Overview

This sample code project demonstrates how to programmatically search for map-based addresses and points of interest using a natural language string, and how to get more information about points of interest that a person selects on the map.
The search results center around the locations visible in the map view.

## Request search completions
``MKLocalSearchCompleter`` retrieves autocomplete suggestions for a partial search query within a map region. A person can type "cof", and a search completion suggests "coffee" as the query string. As the person types a query into a search bar, the sample app updates the query. In SwiftUI, the sample creates the search field using the <doc://com.apple.documentation/documentation/swiftui/view/searchable(text:placement:prompt:)> modifier.

``` swift
.searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: searchPrompt)
```
[View in Source](x-source-tag://SidebarView)

As someone types a query into a search bar, the sample app updates the ``MKLocalSearchCompleter/queryFragment`` for the search completion through the `searchQuery` binding.

``` swift
/// Ask for completion suggestions based on the query text.
func provideCompletionSuggestions(for query: String) {
    /**
     Configure the search to return completion results based only on the options in the app. For example,
     someone can configure the app to exclude specific point-of-interest categories, or to only return results for addresses.
     */
    searchCompleter?.resultTypes = mapConfiguration.resultType.completionResultType
    searchCompleter?.regionPriority = mapConfiguration.regionPriority.localSearchRegionPriority
    if mapConfiguration.resultType == .pointsOfInterest {
        searchCompleter?.pointOfInterestFilter = mapConfiguration.pointOfInterestOptions.filter
    } else if mapConfiguration.resultType == .addresses {
        searchCompleter?.addressFilter = mapConfiguration.addressOptions.filter
    }
    
    searchCompleter?.region = mapConfiguration.region
    searchCompleter?.queryFragment = query
}
```
[View in Source](x-source-tag://ProvideCompletions)

## Receive completion results
Completion results represent fully formed query strings based on the query fragment someone types.
The sample app uses completion results to populate UI elements to quickly fill in a search query.
The app receives the latest completion results as an array of ``MKLocalSearchCompletion`` objects by adopting the ``MKLocalSearchCompleterDelegate`` protocol.

``` swift
nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    Task { @MainActor in
        /**
         As a person types, new completion suggestions continuously return to this method. Update the property storing the current
         results, so that the app UI can observe the change and display the updated suggestions.
         */
        let suggestedCompletions = completer.results
        resultStreamContinuation?.yield(suggestedCompletions)
    }
}
```
[View in Source](x-source-tag://CompletionResults)


The app uses an <doc://com.apple.documentation/documentation/swift/asyncstream> to deliver the completion results to the UI, which the `SidebarView`  stores in its `searchCompletions` property.
The app displays the search suggestions with the <doc://com.apple.documentation/documentation/swiftui/View/searchSuggestions(_:)> modifier, which takes a binding to the `searchCompletions` property.

``` swift
.searchSuggestions {
    // Treat each `MKMapItem` object as unique, using `\.self` for the identity. The `identifier` property of `MKMapItem`
    // is an optional value, and the meaning of the identifier for `MKMapItem` doesn't have the same semantics as
    // the `Identifable` protocol that `ForEach` requires.
    ForEach($searchCompletions, id: \.self) { completion in
        SearchCompletionItemView(completion: completion.wrappedValue)
        .onTapGesture {
            convertSearchCompletionToSearchResults(completion.wrappedValue)
        }
    }
}
```
[View in Source](x-source-tag://SidebarView)

## Highlight the relationship of a query fragment to the suggestion

Within the UI elements that represent each query result, the sample code uses the ``MKLocalSearchCompletion/titleHighlightRanges`` on an `MKLocalSearchCompletion` to show how the query someone enters relates to the suggested result.
For example, the following code applies a highlight with <doc://com.apple.documentation/documentation/foundation/NSAttributedString>:

``` swift
private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
    let attributes = [NSAttributedString.Key.backgroundColor: UIColor(named: "suggestionHighlight")!]
    let highlightedString = NSMutableAttributedString(string: text)

    // Each `NSValue` wraps an `NSRange` that functions as a style attribute's range with `NSAttributedString`.
    let ranges = rangeValues.map { $0.rangeValue }
    for range in ranges {
        highlightedString.addAttributes(attributes, range: range)
    }

    return highlightedString
}
```
[View in Source](x-source-tag://HighlightFragment)

## Search for map items

An ``MKLocalSearch.Request`` takes either an `MKLocalSearchCompletion` or a natural language query string, and returns an array of ``MKMapItem`` objects.
Each `MKMapItem` represents a geographic location, like a specific address, that matches the search query.
The sample code asynchronously retrieves the array of `MKMapItem` objects by calling ``MKLocalSearch/start(completionHandler:)`` on ``MKLocalSearch``.

``` swift
let search = MKLocalSearch(request: request)
currentSearch = search
defer {
    // After the search completes, the reference is no longer needed.
    currentSearch = nil
}

var results: [MKMapItem]

do {
    let response = try await search.start()
    results = response.mapItems
} catch let error {
    searchLogging.error("Search error: \(error.localizedDescription)")
    results = []
}
```
[View in Source](x-source-tag://StartSearch)

    
## Allow someone to select points of interest on the map
If a person is exploring the map, they can get information for a point of interest by tapping it.
To provide these interactions, the sample code enables selectable map features as follows:

``` swift
// Use the standard map style, with an option to display specific point-of-interest categories.
.mapStyle(.standard(pointsOfInterest: mapModel.searchConfiguration.pointOfInterestOptions.categories))

// Only allow selection for points of interest, and disable selection of other labels, like city names.
.mapFeatureSelectionDisabled { feature in
    feature.kind != MapFeature.FeatureKind.pointOfInterest
}

/*
 The selection accessory allows people to tap on map features and get more detailed information, which displays
 as either a sheet or a callout according to the `style` parameter. Along with the `selection` binding, this determines
 which feature to display additional information for.
 
 This modifier differs from the `mapItemDetailSelectionAccessory(:_) modifier, which enables the same selection
 behaviors on annotations that the app adds to `Map` for search results.
 */
.mapFeatureSelectionAccessory(.automatic)
```
[View in Source](x-source-tag://SelectableFeature)

When someone taps a point of interest, the system presents the map item's details,
including information like a phone number, business hours, and buttons to start navigation to the location using Apple Maps.
The system presents the information using the style that the ``mapFeatureSelectionAccessory(_:)`` modifier configures.
The sample app uses the ``MapItemDetailSelectionAccessoryStyle/automatic`` style, but the ``MapItemDetailSelectionAccessoryStyle`` structure offers several other options.

## Persist and retrieve map items

If someone is exploring the map, they may want the app to store places they looked at so that they can come back to them later, including across app launches.
`MKMapItem` has an ``MKMapItem/identifier`` property, which the app stores in its `VisitedPlace` model using ``SwiftData``.

``` swift
guard let identifier = mapItem.identifier else { return }
let visit = VisitedPlace(id: identifier.rawValue)
```
[View in Source](x-source-tag://MapItemIdentifier)

When the app launches, it retrieves the history of visited locations from SwiftData.
To get the `MKMapItem` from the previously stored identifier, the app creates an ``MKMapItemRequest`` with the stored identifier and calls ``MKMapItemRequest/getMapItem(completionHandler:)``.

``` swift
@MainActor
func convertToMapItem() async -> MKMapItem? {
    guard let identifier = MKMapItem.Identifier(rawValue: id) else { return nil }
    let request = MKMapItemRequest(mapItemIdentifier: identifier)
    var mapItem: MKMapItem? = nil
    do {
        mapItem = try await request.mapItem
    } catch let error {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Map Item Requests")
        logger.error("Getting map item from identifier failed. Error: \(error.localizedDescription)")
    }
    return mapItem
}
```
[View in Source](x-source-tag://MapItemRequest) 

