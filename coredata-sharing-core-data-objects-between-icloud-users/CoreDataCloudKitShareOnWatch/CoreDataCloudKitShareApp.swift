/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI app for watchOS.
*/

import SwiftUI

@main
struct CoreDataCloudKitShareApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: AppDelegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PhotoGridView()
                .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
        }
    }
}
