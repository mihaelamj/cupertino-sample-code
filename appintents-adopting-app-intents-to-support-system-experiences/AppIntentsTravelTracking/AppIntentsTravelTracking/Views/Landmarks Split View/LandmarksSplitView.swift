/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct LandmarksSplitView: View {
    @Environment(ModelData.self) var modelData
    @Environment(Navigator.self) var navigator

    @State private var preferredColumn: NavigationSplitViewColumn = .sidebar

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        @Bindable var modelData = modelData
        @Bindable var navigator = navigator

        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            if modelData.searchTerm.isEmpty && modelData.searchTokens.isEmpty {
                List(selection: $navigator.navigationOption) {
                    Section {
                        ForEach(NavigationOption.allCases) { page in
                            NavigationLink(value: page) {
                                Label(page.name, systemImage: page.symbolName)
                            }
                        }
                    }
                }
            } else {
                LandmarksGrid(landmarks: $modelData.filteredLandmarks, isShowingLandmarksSelection: false)
                    .padding()
            }
        } detail: {
            NavigationStack {
                navigator.navigationOption?.viewForPage()
            }
        }
        .searchable(text: $modelData.searchTerm, tokens: $modelData.searchTokens, prompt: "Search") { value in
            switch value {
            case .image:
                Label("Image", systemImage: "photo")
            }
        }
        #if os(iOS)
        .onAppIntentExecution(NavigateIntent.self) { intent in
            navigator.navigate(to: intent.navigationOption)
        }
        .onAppIntentExecution(OpenCollectionIntent.self) { intent in
            Task {
                if let collection = modelData.collection(id: intent.target.id) {
                    await navigator.navigate(to: collection)
                }
            }
        }
        .onAppIntentExecution(OpenLandmarkIntent.self) { intent in
            Task {
                await navigator.navigate(to: intent.target)
            }
        }
        .onAppIntentExecution(GetCrowdStatusIntent.self) { intent in
            Task {
                await navigator.navigate(to: intent.landmark)
            }
        }
        #endif
        #if canImport(VisualIntelligence)
        .onAppIntentExecution(ShowSearchResultsIntent.self) { _ in
            Task {
                navigator.navigationOption = nil

                try! await Task.sleep(for: .seconds(0.25))

                modelData.searchTokens = [.image]
            }
        }
        #endif
    }
}

#Preview {
    LandmarksSplitView()
        .environment(ModelData())
}
