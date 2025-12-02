/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that manages photo ratings.
*/

import SwiftUI
import CoreData

struct RatingView: View {
    @Binding var activeSheet: ActiveSheet?
    
    @State private var toggleProgress: Bool = false
    @State private var wasPhotoDeleted = false
    private let photo: Photo
    private let canUpdate: Bool

    private let fetchRequest: FetchRequest<Rating>
    private var ratings: FetchedResults<Rating> {
        return fetchRequest.wrappedValue
    }

    init(activeSheet: Binding<ActiveSheet?>, photo: Photo) {
        _activeSheet = activeSheet
        self.photo = photo

        let nsFetchRequest = Rating.fetchRequest()
        nsFetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Rating.value, ascending: true)]
        nsFetchRequest.predicate = NSPredicate(format: "photo = %@", photo)
        fetchRequest = FetchRequest(fetchRequest: nsFetchRequest, animation: .default)
        
        let container = PersistenceController.shared.persistentContainer
        canUpdate = container.canUpdateRecord(forManagedObjectWith: photo.objectID)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if wasPhotoDeleted {
                    Text("The photo for rating was deleted remotely.").padding()
                    Spacer()
                } else {
                    ratingListView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .dismiss) {
                    Button("Dismiss") { activeSheet = nil }
                }
            }
            .listStyle(.clearRowShape)
            .navigationTitle("Rating")
        }
        .frame(idealWidth: Layout.sheetIdealWidth, idealHeight: Layout.sheetIdealHeight)
        .onReceive(NotificationCenter.default.storeDidChangePublisher) { _ in
            wasPhotoDeleted = photo.isDeleted
        }
    }
    
    @ViewBuilder
    private func ratingListView() -> some View {
        ZStack {
            List {
                Section(header: sectionHeader()) {
                    sectionContent()
                }
            }
            if toggleProgress {
                ProgressView()
            }
        }
    }
        
    @ViewBuilder
    private func sectionHeader() -> some View {
        if canUpdate {
            RatingListHeader(toggleProgress: $toggleProgress, photo: photo)
        }
    }
    
    @ViewBuilder
    private func sectionContent() -> some View {
        ForEach(ratings, id: \.self) { rating in
            HStack {
                ForEach(1..<6) { index in
                    Image(systemName: rating.value >= index ? "star.fill": "star")
                        .foregroundColor(.gray)
                }
            }
        }
        .onDelete(perform: deleteRatings)
        .emptyListPrompt(ratings.isEmpty, prompt: "No rating.")
    }
        
    private func deleteRatings(offsets: IndexSet) {
        if canUpdate {
            withAnimation {
                let ratingsToBeDeleted = offsets.map { ratings[$0] }
                for rating in ratingsToBeDeleted {
                    PersistenceController.shared.deleteRating(rating)
                }
            }
        }
    }
}

struct RatingListHeader: View {
    @Binding var toggleProgress: Bool
    let photo: Photo
    
    @State private var ratingValue: Int = 3

    var body: some View {
        HStack {
            ForEach(1..<6, id: \.self) { index in
                Button(action: { ratingValue = index }) {
                    Image(systemName: ratingValue >= index ? "star.fill": "star")
                }
                .buttonStyle(.plain)
                Spacer().frame(minWidth: 1, idealWidth: 20, maxWidth: 30)
            }
            Spacer()
            IconOnlyButton("Add", systemImage: "plus.circle", font: .system(size: 20)) {
                addRating()
            }
        }
        .padding([.bottom])
    }
    /**
     Toggle the progress view.
     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1): Allow 0.1 second to show the progress view.
     */
    private func addRating() {
        toggleProgress.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                PersistenceController.shared.addRating(value: Int16(ratingValue), relateTo: photo)
                toggleProgress.toggle()
            }
        }
    }
}
