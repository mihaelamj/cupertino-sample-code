/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that manages the actions on a photo.
*/

import SwiftUI
import CoreData
import CloudKit

struct PhotoContextMenu: View {
    @Binding var activeSheet: ActiveSheet?
    @Binding var nextSheet: ActiveSheet?
    private let photo: Photo
    /**
     Disable the menus by default.
     */
    @State private var isPhotoShared: Bool = true
    @State private var hasAnyShare: Bool = false
    
    @State private var toggleProgress: Bool = false
    
    init(activeSheet: Binding<ActiveSheet?>, nextSheet: Binding<ActiveSheet?>, photo: Photo) {
        _activeSheet = activeSheet
        _nextSheet = nextSheet
        self.photo = photo
    }

    var body: some View {
        /**
         CloudKit has a limit on how many zones a database can have. To avoid reaching the limit,
         apps use the existing share, if possible.
         */
        ZStack {
            MenuScrollView {
                menuButtons()
            }
            if toggleProgress {
                ProgressView()
            }
        }
        .onAppear {
            isPhotoShared = (PersistenceController.shared.existingShare(photo: photo) != nil)
            hasAnyShare = PersistenceController.shared.shareTitles().isEmpty ? false : true
        }
        .onReceive(NotificationCenter.default.storeDidChangePublisher) { notification in
            processStoreChangeNotification(notification)
        }
    }
    
    @ViewBuilder
    private func menuButtons() -> some View {
        /**
         For photos in the private database, allow creating a new share or adding to an existing share.
         For photos in the shared database, allow managing participation.
         */
        if PersistenceController.shared.privatePersistentStore.contains(manageObject: photo) {
            #if os(watchOS)
            Button(action: {
                createNewShare(photo: photo)
            }) {
                MenuButtonLabel(title: "New Share", systemImage: "square.and.arrow.up")
            }
            .disabled(isPhotoShared)
            #else
            ShareLink(item: photo, preview: SharePreview("A cool photo to share!")) {
                MenuButtonLabel(title: "New Share", systemImage: "square.and.arrow.up")
            }
            .disabled(isPhotoShared)
            #endif
            Button(action: {
                activeSheet = .sharePicker(photo)
            }) {
                MenuButtonLabel(title: "Add to Share", systemImage: "square.grid.3x1.folder.badge.plus")
            }
            .disabled(isPhotoShared || !hasAnyShare)
        } else {
            Button(action: {
                manageParticipation(photo: photo)
            }) {
                MenuButtonLabel(title: "Participants", systemImage: "person.2")
            }
        }
        /**
        Tagging and rating.
         */
        if PersistenceController.shared.persistentContainer.canUpdateRecord(forManagedObjectWith: photo.objectID) {
            MenuDivider()
            Button(action: {
                activeSheet = .taggingView(photo)
            }) {
                MenuButtonLabel(title: "Tag", systemImage: "tag")
            }
            Button(action: {
                activeSheet = .ratingView(photo)
            }) {
                MenuButtonLabel(title: "Rate", systemImage: "star")
            }
        }
        /**
         Show the Delete button if the user is editing photos and has the permission to delete.
         */
        if PersistenceController.shared.persistentContainer.canDeleteRecord(forManagedObjectWith: photo.objectID) {
            MenuDivider()
            
            Button(role: .destructive, action: {
                PersistenceController.shared.delete(photo: photo)
                activeSheet = nil
            }) {
                MenuButtonLabel(title: "Delete", systemImage: "trash")
            }
        }
    }
    
    private func manageParticipation(photo: Photo) {
        if let share = PersistenceController.shared.existingShare(photo: photo) {
            activeSheet = .participantView(share)
        } else {
            activeSheet = .managingSharesView
        }
    }

    /**
     Sharing a photo can take a while in watchOS, so dispatch to a global queue so SwiftUI has a chance to show the progress view.
     @State variables are thread-safe, so there's no need to dispatch back the main queue.
     */
    private func createNewShare(photo: Photo) {
        toggleProgress.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            PersistenceController.shared.shareObject(photo, to: nil) { share, error in
                toggleProgress.toggle()
                if let share = share {
                    nextSheet = .participantView(share)
                    activeSheet = nil
                }
            }
        }
    }
    
    /**
     Ignore the notification in the following cases:
     - It isn't relevant to the private database.
     - It doesn't have a transaction. When a share changes, Core Data triggers a store remote change notification with no transaction.
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
        isPhotoShared = (PersistenceController.shared.existingShare(photo: photo) != nil)
        hasAnyShare = PersistenceController.shared.shareTitles().isEmpty ? false : true
    }
}
