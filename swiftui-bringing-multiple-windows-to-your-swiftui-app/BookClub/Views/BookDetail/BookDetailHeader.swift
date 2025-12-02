/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book detail subview displaying the book metadata and the user's
 reading progress.
*/

import SwiftUI

struct BookDetailHeader: View {
    var dataModel: ReadingListModel
    @ObservedObject var currentlyReading: CurrentlyReading
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    
    init(
        dataModel: ReadingListModel,
        book currentlyReading: CurrentlyReading
    ) {
        self.dataModel = dataModel
        self.currentlyReading = currentlyReading
    }
    
    var body: some View {
        HStack(alignment: .top) {
            #if os(macOS)
            VStack {
                bookCover
                    .padding(.bottom, 5)
                progressView
            }
            VStack(alignment: .leading) {
                title
                author
                description
                    .padding(.top, 5)
            }
            .padding(.leading, 5)
            #else
            if isCompactVerticalSizeClass {
                VStack(alignment: .leading) {
                    HStack {
                        VStack {
                            bookCover
                                .padding(.bottom, 5)
                            progressView
                        }
                        VStack(alignment: .leading) {
                            author
                                .padding(.bottom, 5)
                            description
                            Spacer()
                            ButtonFooter(currentlyReading: currentlyReading)
                        }
                        .padding(.leading)
                    }
                }
            } else {
                VStack(alignment: .leading) {
                    author
                        .padding(.leading, isCompactHorizonalSizeClass ? 0 : 5)
                    HStack(alignment: .bookCover) {
                        VStack {
                            bookCover
                                .padding(.bottom, 5)
                                .alignmentGuide(.bookCover) { dimensions in
                                    dimensions[VerticalAlignment.center]
                                }
                            progressView
                        }
                        VStack(alignment: .trailing) {
                            description
                                .padding(.leading)
                                .alignmentGuide(.bookCover) { dimensions in
                                    dimensions[VerticalAlignment.center]
                                }
                            if isCompactHorizonalSizeClass {
                                ButtonFooter(currentlyReading: currentlyReading)
                            }
                        }
                    }
                }
            }
            #endif
        }
    }
    
    var bookCover: some View {
        BookCover(
            book: currentlyReading.book,
            size: isCompactHorizonalSizeClass ? 148 : 172)
    }
    
    var progressView: some View {
        StackedProgressView(value: currentlyReading.currentProgress)
    }
    
    var isCompactHorizonalSizeClass: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }
    
    var isCompactVerticalSizeClass: Bool {
        #if os(iOS)
        return verticalSizeClass == .compact
        #else
        return false
        #endif
    }
    
    var title: some View {
        Text(currentlyReading.book.title)
            .font(.title)
            .fontWeight(.medium)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
    }
    
    var author: some View {
        Text(currentlyReading.book.author)
            .font(.title3)
            .foregroundStyle(.secondary)
    }
    
    var description: some View {
        Text(currentlyReading.book.description)
            .font(.callout)
            .lineLimit(isCompactHorizonalSizeClass ? 7 : nil)
    }
}

extension VerticalAlignment {
    private struct BookCover: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat {
            dimensions[VerticalAlignment.center]
        }
    }
    
    fileprivate static let bookCover = VerticalAlignment(BookCover.self)
}

private struct ButtonFooter: View {
    var currentlyReading: CurrentlyReading
    @State private var showBookDescription = false
    
    var body: some View {
        HStack(alignment: .bottom) {
            Spacer()
            Button {
                showBookDescription.toggle()
            } label: {
                Label(
                    "Read full description",
                    systemImage: "ellipsis.circle")
            }
            UpdateReadingProgressButton(book: currentlyReading)
            MarkAsFinishedButton(book: currentlyReading)
        }
        .buttonStyle(.bordered)
        .labelStyle(.iconOnly)
        .sheet(isPresented: $showBookDescription) {
            BookDescriptionSheet(book: currentlyReading.book)
        }
    }
}

private struct BookDescriptionSheet: View {
    var book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Description")
                .font(.title3)
                .fontWeight(.medium)
                .padding(.vertical)
            Text(book.description)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            Spacer()
        }
        .scenePadding()
    }
}

struct BookDetailHeader_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(ProgressEditorModel.mocks, id: \.self) { model in
                BookDetailHeader(
                    dataModel: ReadingListModel(),
                    book: CurrentlyReading.mock)
            }
        }
    }
}
