/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that picks an existing share.
*/

import SwiftUI
import CoreData
import CloudKit

struct SharePickerView<ActionView: View>: View {
    @Binding private var activeSheet: ActiveSheet?
    private let actionView: (String) -> ActionView
    @State private var shareTitles = PersistenceController.shared.shareTitles()

    init(activeSheet: Binding<ActiveSheet?>, @ViewBuilder actionView: @escaping (String) -> ActionView) {
        _activeSheet = activeSheet
        self.actionView = actionView
    }

    var body: some View {
        NavigationStack {
            VStack {
               if shareTitles.isEmpty {
                   Text("No share exists. Please create a new share for a photo, then try again.")
                       .padding()
                   Spacer()
               } else {
                   List(shareTitles, id: \.self) { shareTitle in
                       HStack {
                           Text(shareTitle)
                           Spacer()
                           actionView(shareTitle)
                       }
                   }
               }
            }
            .toolbar {
                ToolbarItem(placement: .dismiss) {
                    Button("Dismiss") {
                        activeSheet = nil
                    }
                }
            }
            .listStyle(.clearRowShape)
            .navigationTitle("Shares")
        }
        .frame(idealWidth: Layout.sheetIdealWidth, idealHeight: Layout.sheetIdealHeight)
        .onReceive(NotificationCenter.default.storeDidChangePublisher) { notification in
            processStoreChangeNotification(notification)
        }
    }
    
    /**
     Update the share list, if necessary. Ignore the notification in the following cases:
     - The notification isn't relevant to the private database.
     - The notification transaction isn't empty. When a share changes, Core Data triggers a store remote change notification with no transaction.
     */
    private func processStoreChangeNotification(_ notification: Notification) {
        guard let storeUUID = notification.userInfo?[UserInfoKey.storeUUID] as? String,
              storeUUID == PersistenceController.shared.privatePersistentStore.identifier else {
            return
        }
        guard let transactions = notification.userInfo?[UserInfoKey.transactions] as? [NSPersistentHistoryTransaction],
              transactions.isEmpty else {
            return
        }
        shareTitles = PersistenceController.shared.shareTitles()
    }
}
