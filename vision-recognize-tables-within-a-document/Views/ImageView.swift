/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the captured image and runs table detection.
*/

import SwiftUI
import Vision

struct ImageView: View {
    let imageData: Data
    @State private var viewModel = VisionModel()
    @State private var isPopoverPresented = false
    @State private var isAlertShowing = false
    @State private var selectedCell: TableCell? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                VStack {
                    // Navigation buttons to retake photo, view or export data.
                    HStack {
                        Spacer()
                        NavigationLink("Retake photo") {
                            ContentView()
                        }
                            .buttonStyle(RoundedButton())
                            .navigationBarBackButtonHidden()
                        if !viewModel.contacts.isEmpty {
                            Spacer()
                            NavigationLink("View Contacts") {
                                ContactView(contacts: viewModel.contacts)
                            }.buttonStyle(RoundedButton())
                        }
                        if viewModel.table != nil {
                            Spacer()
                            Button("Copy Table", action: copyTable)
                                .buttonStyle(RoundedButton())
                        }
                        Spacer()
                    }
                }
                // Convert the image data to a `UIImage`, and display it in an `Image` view.
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .overlay {
                            if let table = viewModel.table {
                                GeometryReader { geometry in
                                    ZStack {
                                        // Draw bounding boxes around the table and its cells.
                                        BoundingBox(region: table.boundingRegion)
                                            .stroke(.blue, lineWidth: 4.0)
                                            .contentShape(Rectangle())
                                        ForEach(table.rows, id: \.hashValue) { row in
                                            ForEach(row, id: \.hashValue) { cell in
                                                BoundingBox(region: cell.content.boundingRegion)
                                                    .stroke(.blue, style: .init(lineWidth: 2.0, dash: [5]))
                                            }
                                        }
                                    }
                                    .onTapGesture { point in
                                        selectCell(containing: point, in: geometry.size)
                                    }
                                }
                            }
                        }
                        .padding()
                        .popover(isPresented: $isPopoverPresented,
                                 attachmentAnchor: .point(selectedCell?.location ?? .bottom)
                        ) {
                            makePopoverView()
                                .padding(20)
                                .presentationCompactAdaptation(.popover)
                        }
                }
            }
            if isAlertShowing {
                makeAlert()
            }
        }
        .task {
            // Process the image with Vision's document recognition.
            await viewModel.recognizeTable(in: imageData)
        }
    }
    
    @ViewBuilder
    private func makePopoverView() -> some View {
        switch selectedCell?.content {
        case .email(let string):
            Link(destination: URL(string: "mailto:\(string)")!) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text(string)
                }
            }
        case .phone(let string):
            Link(destination: URL(string: "imessage:\(string)")!) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text(string)
                }
            }
        case .text(let string):
            Text(string)
        case nil:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func makeAlert() -> some View {
        Text("Table copied to clipboard!")
            .font(.callout)
            .padding(20)
            .background(Color.green.clipShape(.buttonBorder))
            .transition(.move(edge: .top))
            .frame(maxHeight: .infinity, alignment: .top)
    }

    /// Copy the detected table to the clipboard and show an alert upon success.
    private func copyTable() {
        Task {
            UIPasteboard.general.string = try await viewModel.exportTable()
            withAnimation {
                isAlertShowing = true
            }
            try? await Task.sleep(for: .seconds(5))
            withAnimation {
                isAlertShowing = false
            }
        }
    }
    
    /// Select the table cell that the user tapped on.
    private func selectCell(containing point: CGPoint, in viewBounds: CGSize) {
        // Convert the screen point to normalized coordinates.
        let point = NormalizedPoint(imagePoint: point, in: viewBounds)
        // Convert to Vision's coordinate system.
        let visionPoint = point.verticallyFlipped()
        // Find the table cell that contains this point.
        selectedCell = viewModel.table?.cell(at: visionPoint)
        if selectedCell != nil {
            isPopoverPresented = true
        }
    }
}

struct RoundedButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .font(.headline)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
