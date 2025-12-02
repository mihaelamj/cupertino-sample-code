/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that manages a photo collection.
*/

import SwiftUI
import CoreData
import CloudKit

enum ActiveSheet: Identifiable, Equatable {
    #if os(watchOS)
    case photoContextMenu(Photo) // .contextMenu is deprecated in watchOS, so use action list instead.
    #endif
    case fullImageView(Photo)
    case cloudSharingSheet(CKShare)
    case managingSharesView
    case sharePicker(Photo)
    case taggingView(Photo)
    case ratingView(Photo)
    case participantView(CKShare)
    /**
     Use the enumeration member name string as the identifier for Identifiable.
     In the case where an enumeration has an associated value, use the label, which is equal to the member name string.
     */
    var id: String {
        let mirror = Mirror(reflecting: self)
        if let label = mirror.children.first?.label {
            return label
        } else {
            return "\(self)"
        }
    }
}

struct PhotoGridView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [SortDescriptor(\.uniqueName)],
                  animation: .default
    ) private var photos: FetchedResults<Photo>

    @State private var activeSheet: ActiveSheet?
    /**
     The next active sheet to present after dismissing the current sheet.
     ManagingSharesView uses this variable to switch to the participant view.
     */
    @State private var nextSheet: ActiveSheet?
    private let persistenceController = PersistenceController.shared

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    if photos.isEmpty {
                        Text("Tap the add (+) button on the iOS app to add a photo.").padding()
                        Spacer()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: Layout.gridItemSize.width))]) {
                            ForEach(photos, id: \.self) { photo in
                                gridItemView(photo: photo, itemSize: Layout.gridItemSize)
                            }
                        }
                    }
                }
            }
            .toolbar { toolbarItems() }
            .navigationTitle("Photos")
            .sheet(item: $activeSheet, onDismiss: sheetOnDismiss) { item in
                sheetView(with: item)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(NotificationCenter.default.storeDidChangePublisher) { notification in
            processStoreChangeNotification(notification)
        }
    }
    
    @ViewBuilder
    private func gridItemView(photo: Photo, itemSize: CGSize) -> some View {
        #if os(watchOS)
        PhotoGridItemView(photo: photo, itemSize: Layout.gridItemSize)
            .onLongPressGesture {
                activeSheet = .photoContextMenu(photo)
            }
        #else
        PhotoGridItemView(photo: photo, itemSize: Layout.gridItemSize)
            .contextMenu {
                PhotoContextMenu(activeSheet: $activeSheet, nextSheet: $nextSheet, photo: photo)
            }
            .onTapGesture {
                activeSheet = .fullImageView(photo)
            }
        #endif
    }

    @ToolbarContentBuilder
    private func toolbarItems() -> some ToolbarContent {
        #if os(watchOS)
        ToolbarItem(placement: .automatic) {
            HStack {
                Spacer()
                PhotoSelectorView()
                    .padding(.trailing, 20)
                IconOnlyButton("Manage Shares", systemImage: "person.2.badge.gearshape", font: .system(size: 18)) {
                    activeSheet = .managingSharesView
                }
                .padding(.trailing, 10)
            }
            .padding(.bottom)
        }
        #else
        ToolbarItem(placement: .firstItem) {
            PhotoSelectorView()
        }
        ToolbarItem(placement: .secondItem) {
            IconOnlyButton("Manage Shares", systemImage: "person.2.badge.gearshape", font: .system(size: 16)) {
                activeSheet = .managingSharesView
            }
        }
        #endif
    }

    @ViewBuilder
    private func sheetView(with item: ActiveSheet) -> some View {
        switch item {
        #if os(watchOS)
        case .photoContextMenu(let photo):
            PhotoContextMenu(activeSheet: $activeSheet, nextSheet: $nextSheet, photo: photo)
        #endif
        
        case .fullImageView(let photo):
            FullImageView(activeSheet: $activeSheet, photo: photo)
            
        case .cloudSharingSheet(_):
            /**
             Reserve this case for something like CloudSharingSheet(activeSheet: $activeSheet, share: share).
             */
            EmptyView()
        case .managingSharesView:
            ManagingSharesView(activeSheet: $activeSheet, nextSheet: $nextSheet)

        case .sharePicker(let photo):
            AddToExistingShareView(activeSheet: $activeSheet, photo: photo)

        case .taggingView(let photo):
            TaggingView(activeSheet: $activeSheet, photo: photo, affectedStore: photo.persistentStore)

        case .ratingView(let photo):
            RatingView(activeSheet: $activeSheet, photo: photo)

        case .participantView(let share):
            ParticipantView(activeSheet: $activeSheet, share: share)
        }
    }
    
    /**
     Present the next active sheet, if necessary.
     Dispatch asynchronously to the next run loop so the presentation occurs after the current sheet's dismissal.
     */
    private func sheetOnDismiss() {
        guard let nextActiveSheet = nextSheet else {
            return
        }
        switch nextActiveSheet {
        case .cloudSharingSheet(let share):
            #if os(iOS) || os(macOS)
            DispatchQueue.main.async {
                persistenceController.presentCloudSharingController(share: share)
            }
            #endif
        default:
            DispatchQueue.main.async {
                activeSheet = nextActiveSheet
            }
        }
        nextSheet = nil
    }

    /**
     Merge the transactions, if any.
     */
    private func processStoreChangeNotification(_ notification: Notification) {
        let transactions = persistenceController.photoTransactions(from: notification)
        if !transactions.isEmpty {
            persistenceController.mergeTransactions(transactions, to: viewContext)
        }
    }
}
