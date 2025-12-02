/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app, which creates a scene, containing a window group, displaying
 a reading list view with data populated by the reading list data model.
*/

import SwiftUI

@main
struct BookClubApp: App {
    private var dataModel = ReadingListModel()

    var body: some Scene {
        WindowGroup("Reading List") {
            ReadingList(model: dataModel)
        }
        .commands {
            SidebarCommands()
        }
        #if os(macOS)
        WindowGroup("Book Details", for: Book.ID.self) { $bookId in
            BookDetailWindow(dataModel: dataModel, bookId: $bookId)
        }
        .commandsRemoved()
        
        Window("Reading Activity", id: "activity") {
            ReadingActivityList(activity: dataModel.activity)
                .frame(minWidth: 640, minHeight: 480)
        }
        .keyboardShortcut("1")
        .defaultPosition(.topTrailing)
        .defaultSize(width: 800, height: 600)
        #endif
    }
}
