/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that manages photo tagging.
*/

import SwiftUI
import CoreData

struct TaggingView: View {
    @Binding var activeSheet: ActiveSheet?
    @State private var wasPhotoDeleted: Bool = false
    private let photo: Photo
    /**
     Retrieving the photo's persistent store (photo.persistentStore) is expensive, so cache it with a member variable
     and provide it to FilteredTagList because FilteredTagList refreshes frequently when the user inputs.
     */
    private let affectedStore: NSPersistentStore?

    init(activeSheet: Binding<ActiveSheet?>, photo: Photo, affectedStore: NSPersistentStore?) {
        _activeSheet = activeSheet
        self.photo = photo
        self.affectedStore = affectedStore
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if wasPhotoDeleted {
                    Text("The photo was deleted remotely.").padding()
                    Spacer()
                } else {
                    FilteredTagList(photo: photo, affectedStore: affectedStore)
                }
            }
            .toolbar {
                ToolbarItem(placement: .dismiss) {
                    Button("Dismiss") { activeSheet = nil }
                }
            }
            .listStyle(.clearRowShape)
            .navigationTitle("Tag")
        }
        .frame(idealWidth: Layout.sheetIdealWidth, idealHeight: Layout.sheetIdealHeight)
        .onAppear {
            wasPhotoDeleted = photo.isDeleted
        }
        .onReceive(NotificationCenter.default.storeDidChangePublisher) { _ in
            wasPhotoDeleted = photo.isDeleted
        }
    }
}

struct FilteredTagList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var filterTagName = ""

    private let photo: Photo
    private let canUpdate: Bool
    private let affectedStore: NSPersistentStore?

    @State private var toggleProgress: Bool = false

    private let fetchRequest: FetchRequest<Tag>
    private var tags: [Tag] {
        let predicate = Tag.predicateExcludingDeduplicatedTags(name: filterTagName, useContains: true)
        fetchRequest.wrappedValue.nsPredicate = predicate
        let allTags = Array(fetchRequest.wrappedValue)
        return PersistenceController.shared.filterTags(from: allTags, forTagging: photo)
    }
    
    /**
     Retrieving the photo's persistent store (photo.persistentStore) is expensive, so this view relies on the containing view to provide it.
     */
    init(photo: Photo, affectedStore: NSPersistentStore?) {
        self.photo = photo
        self.affectedStore = affectedStore
        /**
         Use a fetch request with a predicate based on the specified filtered tag name, and specify its affected store.
         */
        let nsFetchRequest = Tag.fetchRequest()
        nsFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        if let affectedStore = affectedStore {
            nsFetchRequest.affectedStores = [affectedStore]
        }
        fetchRequest = FetchRequest(fetchRequest: nsFetchRequest, animation: .default)
        let container = PersistenceController.shared.persistentContainer
        canUpdate = container.canUpdateRecord(forManagedObjectWith: photo.objectID)
    }
    
    var body: some View {
        ZStack {
            #if os(watchOS)
            List {
                sectionHeader()
                sectionContent()
            }
            #else
            List {
                Section(header: sectionHeader()) {
                    sectionContent()
                }
            }
            #endif
            if toggleProgress {
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader() -> some View {
        if canUpdate {
            TagListHeader(toggleProgress: $toggleProgress, filterTagName: $filterTagName, tags: tags, photo: photo)
        }
    }
    
    @ViewBuilder
    private func sectionContent() -> some View {
        let photoTagNotDeduplicated = photo.tagsNotDeduplicated
        ForEach(tags) { tag in
            HStack {
                Text("\(tag.name!)")
                Spacer()
                if let photoTags = photoTagNotDeduplicated, photoTags.contains(tag) {
                    Image(systemName: "checkmark")
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { toggleTagging(tag: tag) }
        }
        .onDelete(perform: deleteTags)
        .emptyListPrompt(tags.isEmpty, prompt: "No matched tag.")
    }
    
    private func deleteTags(offsets: IndexSet) {
        if canUpdate {
            withAnimation {
                let tagsToBeDeleted = offsets.map { tags[$0] }
                for tag in tagsToBeDeleted {
                    PersistenceController.shared.deleteTag(tag)
                }
            }
        }
    }
    
    private func toggleTagging(tag: Tag) {
        if canUpdate {
            PersistenceController.shared.toggleTagging(photo: photo, tag: tag)
        }
    }
}

struct TagListHeader: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var toggleProgress: Bool
    @Binding var filterTagName: String
    
    private let photo: Photo
    private let tags: [Tag]
    
    init(toggleProgress: Binding<Bool>, filterTagName: Binding<String>, tags: [Tag], photo: Photo) {
        _toggleProgress = toggleProgress
        _filterTagName = filterTagName
        self.tags = tags
        self.photo = photo
    }

    var body: some View {
        HStack {
            ClearableTextField(title: "Tag name", text: $filterTagName)
            IconOnlyButton("Add", systemImage: "plus.circle", font: .system(size: 20)) {
                addTag()
            }
            .disabled(filterTagName.isEmpty || tags.map { $0.name }.contains(filterTagName))
        }
    }
    
    private func addTag() {
        guard !filterTagName.isEmpty else {
            return
        }
        toggleProgress.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                PersistenceController.shared.addTag(name: filterTagName, relateTo: photo)
                toggleProgress.toggle()
                filterTagName = ""
            }
        }
    }
}
