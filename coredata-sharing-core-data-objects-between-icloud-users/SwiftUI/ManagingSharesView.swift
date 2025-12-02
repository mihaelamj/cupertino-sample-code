/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that manages existing shares.
*/

import SwiftUI
import CoreData
import CloudKit

struct ManagingSharesView: View {
    @Binding var activeSheet: ActiveSheet?
    @Binding var nextSheet: ActiveSheet?
    @State private var toggleProgress: Bool = false

    var body: some View {
        ZStack {
            SharePickerView(activeSheet: $activeSheet) { shareTitle in
                if let share = PersistenceController.shared.share(with: shareTitle) {
                    actionButtons(for: share)
                }
            }
            if toggleProgress {
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    private func actionButtons(for share: CKShare) -> some View {
        IconOnlyButton("Participants", systemImage: "person.2") {
            nextSheet = .participantView(share)
            activeSheet = nil
        }
        .padding(.trailing)
        
        #if os(iOS) || os(macOS)
        IconOnlyButton("Manage with Share UI", systemImage: "gearshape") {
            nextSheet = .cloudSharingSheet(share)
            activeSheet = nil
        }
        #endif
    }
}
