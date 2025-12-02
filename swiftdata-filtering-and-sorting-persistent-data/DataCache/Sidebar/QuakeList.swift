/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sorted and filtered list of earthquakes that the app stores.
*/

import SwiftUI
import SwiftData

/// The sorted and filtered list of earthquakes that the app stores.
struct QuakeList: View {
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var quakes: [Quake]

    @Binding var selectedId: Quake.ID?
    @Binding var selectedIdMap: Quake.ID?

    init(
        selectedId: Binding<Quake.ID?>,
        selectedIdMap: Binding<Quake.ID?>,
        
        searchText: String = "",
        searchDate: Date = .now,
        sortParameter: SortParameter = .time,
        sortOrder: SortOrder = .reverse
    ) {
        _selectedId = selectedId
        _selectedIdMap = selectedIdMap

        let predicate = Quake.predicate(searchText: searchText, searchDate: searchDate)
        switch sortParameter {
        case .time: _quakes = Query(filter: predicate, sort: \.time, order: sortOrder)
        case .magnitude: _quakes = Query(filter: predicate, sort: \.magnitude, order: sortOrder)
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List(quakes, selection: $selectedId) { quake in
                QuakeRow(quake: quake)
            }

#if os(macOS)
            .safeAreaInset(edge: .bottom) {
                QuakeListInfo(count: quakes.count)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

#elseif os(iOS)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    QuakeListInfo(count: quakes.count)
                        .padding(.top)
                }
            }
#endif

            // Synchronize changes from the map back to the main selector.
            .onChange(of: selectedIdMap) { _, selectedIdMap in
                guard selectedId != selectedIdMap else { return }
                selectedId = selectedIdMap

                // When the map selection changes, scroll the list to match.
                if let id = selectedId {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .overlay {
            if viewModel.totalQuakes == 0 {
                ContentUnavailableView("Refresh to load earthquakes", systemImage: "globe")
            } else if quakes.isEmpty {
                ContentUnavailableView.search
            }
        }
   }
}

#Preview {
    QuakeList(selectedId: .constant(nil), selectedIdMap: .constant(nil))
        .environment(ViewModel.preview)
        .modelContainer(PreviewSampleData.container)
}
