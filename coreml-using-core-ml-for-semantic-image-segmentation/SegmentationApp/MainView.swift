/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view.
*/

import SwiftUI

struct MainView: View {
    
    @StateObject var viewModel = ViewModel()
    @State var overlaySize: CGSize = .zero

    var loadModel: Bool

    init(loadModel: Bool = true) {
        self.loadModel = loadModel
    }

    var body: some View {
        VStack(spacing: 20) {
            // Overlay the original image and the image mask.
            ZStack() {
                if let image = viewModel.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay {
                            if let image = viewModel.maskedImage {
                                GeometryReader { bounds in
                                    image
                                        .resizable()
                                        .blendMode(.darken)
                                        .opacity(0.75)
                                        .onTapGesture { location in
                                            // Translate the geometry to the range `([0, 1], [0, 1])`.
                                            let normalizedPosition = CGPoint(
                                                x: min(max(location.x / overlaySize.width, 0), 1),
                                                y: min(max(location.y / overlaySize.height, 0), 1)
                                            )

                                            viewModel.selectLabel(at: normalizedPosition)
                                        }
                                        .onAppear {
                                            overlaySize = bounds.size
                                        }
                                }
                            } else {
                                EmptyView()
                            }
                        }
                } else {
                    EmptyView()
                }
            }
            .frame(maxWidth: 500, maxHeight: 500)

            if viewModel.maskedImage != nil {
                Text("Tap the image to see segment predictions")
            }

            ScrollView {
                PredictedLabelsGridView(
                    predictedLabels: viewModel.predictedLabels,
                    selectedLabel: $viewModel.selectedLabel
                ).padding(8)
                Button("Photos") {
                    viewModel.showPhotoPicker = true
                }
            }

            if viewModel.image == nil {
                Text("Choose a source to start image analysis")
            }

            if !viewModel.isModelLoaded {
                ProgressView("Loading model...")
            }

            if let message = viewModel.errorMessage, !message.isEmpty {
                Text("Error: \(message)")
            }
        }
        .photosPicker(isPresented: $viewModel.showPhotoPicker, selection: $viewModel.selectedPhoto)
        .task {
            if loadModel {
                await viewModel.loadModel()
            }
        }
    }
}

#Preview("Main View") {
    MainView(loadModel: false)
}

struct PredictedLabelsGridView: View {
    var predictedLabels: [String]
    @Binding var selectedLabel: String?

    var body: some View {
        LazyVGrid(
            columns: [.init(
                .adaptive(
                    minimum: PredictedLabelGridCell.cellWidth,
                    maximum: PredictedLabelGridCell.cellWidth
                )
            )]
        ) {
            ForEach(predictedLabels, id: \.self) { label in
                PredictedLabelGridCell(
                    predictedLabel: label,
                    isSelected: Binding<Bool>(
                        get: { label == self.selectedLabel },
                        set: {
                            // Never set this to false directly.
                            if $0 { self.selectedLabel = label }
                        }
                    )
                )
            }
        }
    }
}

#Preview("Predicted Labels Grid") {
    PredictedLabelsGridView(
        predictedLabels: [
            "Lorem", "Ipsum", "Dolor", "Sit", "Amet", "Consectetur", "Adipiscing", "Elit"],
        selectedLabel: .constant("Lorem"))
}

struct PredictedLabelGridCell: View {
    var predictedLabel: String
    @Binding var isSelected: Bool

    static let cellWidth = CGFloat(150)

    var body: some View {
        Text(predictedLabel)
            .padding()
            .frame(width: Self.cellWidth, height: Self.cellHeight)
            .background()
            .clipShape(.rect(cornerRadii: Self.cornerRadii))
            .overlay {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .fill(.clear)
                    .stroke(
                        isSelected ? Color.accentColor : Color.secondary,
                        lineWidth: isSelected ? 3 : 1
                    )
            }
            .onTapGesture {
                isSelected = true
            }
    }

    private static let diameter = CGFloat(22)
    private static let cellHeight = CGFloat(75)
    private static let cornerRadius = CGFloat(10)
    private static let cornerRadii = RectangleCornerRadii(
        topLeading: cornerRadius,
        bottomLeading: cornerRadius,
        bottomTrailing: cornerRadius,
        topTrailing: cornerRadius
    )
    private static let shadowRadius = CGFloat(3)
    private static let borderWidth = CGFloat(3)
}

#Preview("Predicted Label Grid Cell") {
    PredictedLabelGridCell(
        predictedLabel: "Foo",
        isSelected: .constant(true)
    )
}
