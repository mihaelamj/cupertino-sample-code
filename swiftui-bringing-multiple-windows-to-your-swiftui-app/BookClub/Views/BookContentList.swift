/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book content list view showing filtered book results for a given category
 or search query.
*/

import SwiftUI

struct BookContentList: View {
    @ObservedObject var dataModel: ReadingListModel
    @ObservedObject var navigationModel: NavigationModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.isSearching) private var isSearching
    private var searchText: String
    
    init(
        searchText: String,
        dataModel: ReadingListModel,
        navigationModel: NavigationModel
    ) {
        self.searchText = searchText
        self.dataModel = dataModel
        self.navigationModel = navigationModel
    }
    
    var body: some View {
        Group {
            if let category = navigationModel.selectedCategory {
                let items = dataModel.items(for: category, matching: searchText)
                List(selection: $navigationModel.selectedBookIds) {
                    ForEach(items) { currentlyReading in
                        NavigationLink(value: currentlyReading.id) {
                            BookCard(
                                book: currentlyReading.book,
                                progress: currentlyReading.currentProgress,
                                isSelected: isSelected(for: currentlyReading.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .navigationTitle(category.title)
                .contextMenu(forSelectionType: Book.ID.self) { books in
                    BookContextMenu(dataModel: dataModel, bookIds: books)
                } primaryAction: { books in
                    if supportsMultipleWindows {
                        books.forEach { openWindow(value: $0) }
                    } else {
                        books.compactMap { dataModel[book: $0] }
                            .forEach { $0.isFavorited = true }
                    }
                }
                #if os(macOS)
                .frame(minWidth: 240, idealWidth: 240)
                .navigationSubtitle(subtitle(for: items.count))
                #endif
            } else {
                Text("No Category Selected")
                    .font(.title)
                    .foregroundStyle(.tertiary)
            }
        }
        .onDisappear {
            if navigationModel.selectedBookIds.isEmpty {
                navigationModel.selectedCategory = nil
            }
        }
    }
    
    func isSelected(for bookID: Book.ID) -> Bool {
        navigationModel.selectedBookIds.contains(bookID)
    }
    
    #if os(macOS)
    func subtitle(for count: Int) -> String {
        if isSearching {
            return "Found \(count) results"
        } else {
            return count == 1 ? "\(count) Item" : "\(count) Items"
        }
    }
    #endif
}

struct BookContentList_Previews: PreviewProvider {
    static var previews: some View {
        let dataModel = ReadingListModel()
        let navigationModel = NavigationModel()
        return Group {
            BookContentList(
                searchText: "",
                dataModel: dataModel,
                navigationModel: navigationModel)
            
            BookContentList(
                searchText: "Jane",
                dataModel: dataModel,
                navigationModel: navigationModel)
            
            BookContentList(
                searchText: "",
                dataModel: dataModel,
                navigationModel: navigationModel)
                .environment(\.locale, .italian)
            
            BookContentList(
                searchText: "Jane",
                dataModel: dataModel,
                navigationModel: navigationModel)
                .environment(\.locale, .italian)
        }
    }
}
