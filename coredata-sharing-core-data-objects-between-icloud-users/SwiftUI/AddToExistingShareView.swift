/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that adds a photo to an existing share.
*/

import SwiftUI
import CoreData
import CloudKit

struct AddToExistingShareView: View {
    @Binding var activeSheet: ActiveSheet?
    var photo: Photo
    @State private var toggleProgress: Bool = false

    /**
     The sample app doesn’t allow adding a photo existing in the private persistent store to a share from the participant side.
     Real-world apps that need to do so can create a new object, relate it to a shared object, and save it, like what the sample
     app does when adding a new tag for a shared photo.
     */
    var body: some View {
        ZStack {
            SharePickerView(activeSheet: $activeSheet) { shareTitle in
                IconOnlyButton("Add", systemImage: "square.grid.3x1.folder.badge.plus") {
                    sharePhoto(photo, shareTitle: shareTitle)
                }
                .disabled(PersistenceController.shared.isParticipatingShare(with: shareTitle))
            }
            if toggleProgress {
                ProgressView()
            }
        }
    }
    
    private func sharePhoto(_ unsharedPhoto: Photo, shareTitle: String?) {
        toggleProgress.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let persistenceController = PersistenceController.shared
            if let shareTitle = shareTitle, let share = persistenceController.share(with: shareTitle) {
                persistenceController.shareObject(unsharedPhoto, to: share)
            }
            toggleProgress.toggle()
            activeSheet = nil
        }
    }
}
