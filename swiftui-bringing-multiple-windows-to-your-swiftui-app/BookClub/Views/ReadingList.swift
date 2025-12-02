/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main reading list view for the app for the app's root scene.
*/

import SwiftUI

struct ReadingList: View {
    var dataModel: ReadingListModel
    @SceneStorage("navigation") private var navigationData: Data?
    @StateObject private var navigationModel = NavigationModel()
    @State private var searchText = ""
    
    init(model: ReadingListModel) {
        dataModel = model
    }

    var body: some View {
        NavigationSplitView(
            columnVisibility: $navigationModel.columnVisibility
        ) {
            Sidebar(
                searchText: searchText,
                dataModel: dataModel,
                navigationModel: navigationModel)
        } content: {
            BookContentList(
                searchText: searchText,
                dataModel: dataModel,
                navigationModel: navigationModel)
            .searchable(text: $searchText)
        } detail: {
            BookDetail(
                dataModel: dataModel,
                bookIds: navigationModel.selectedBookIds)
        }
        .task {
            if let data = navigationData {
                navigationModel.jsonData = data
            }
            for await jsonData in navigationModel.$jsonData.values {
                if let data = jsonData {
                    navigationData = data
                }
            }
        }
    }
}

struct ReadingList_Previews: PreviewProvider {
    static var previews: some View {
        let model = ReadingListModel()
        return Group {
            ReadingList(model: model)
            ReadingList(model: model)
                .environment(\.locale, .italian)
        }
    }
}
