/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Sidebar view displaying a list of book categories.
*/

import SwiftUI

struct Sidebar: View {
    var searchText: String
    var dataModel: ReadingListModel
    @ObservedObject var navigationModel: NavigationModel
    @State private var selectedBookIds: Set<Book.ID> = []

    var body: some View {
        List(selection: $navigationModel.selectedCategory) {
            ForEach(dataModel.categories) { category in
                NavigationLink(value: category) {
                    Label(category.title, systemImage: category.iconName)
                }
            }
        }
        .navigationTitle("Categories")
        .onChange(of: navigationModel.selectedBookIds) { bookIds in
            selectedBookIds = bookIds
        }
        .onChange(of: searchText) {
            navigationModel.selectedBookIds = $0.isEmpty ? selectedBookIds : []
        }
        .onChange(of: navigationModel.selectedCategory) { _ in
            navigationModel.selectedBookIds = []
        }
        #if os(macOS)
        .frame(minWidth: 200, idealWidth: 200)
        #endif
    }
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        let dataModel = ReadingListModel()
        let navigationModel = NavigationModel()
        return Group {
            Sidebar(
                searchText: "",
                dataModel: dataModel,
                navigationModel: navigationModel)
            
            Sidebar(
                searchText: "Jane",
                dataModel: dataModel,
                navigationModel: navigationModel)
            
            Sidebar(
                searchText: "",
                dataModel: dataModel,
                navigationModel: navigationModel)
            .environment(\.locale, .italian)
            
            Sidebar(
                searchText: "Jane",
                dataModel: dataModel,
                navigationModel: navigationModel)
            .environment(\.locale, .italian)
        }
    }
}
