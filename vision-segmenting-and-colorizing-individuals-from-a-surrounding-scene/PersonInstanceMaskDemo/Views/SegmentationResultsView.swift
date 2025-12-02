/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that displays the segmentation request results.
*/

import SwiftUI

struct SegmentationResultsView: View {
    var image: CIImage
    @StateObject var viewModel = SegmentationModel()
    @State var isShowingDialog = false
    @State var requestStatus: SegmentationModel.RequestState = .loading
    
    // The view that renders the segmentation mask image and allows people to toggle segments on or off.
    struct SegmentationMaskView: View {
        @ObservedObject var viewModel: SegmentationModel
        var body: some View {
            if let image = viewModel.segmentedImage {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .onTapGesture { location in
                            Task {
                                await viewModel.toggleSegmentAtLocation(location, extent: geometry.size)
                            }
                        }
                }
                .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
            }
            HStack {
                ForEach(0..<viewModel.segmentationCount, id: \.self) {index in
                    Button(String(index)) {
                        Task {
                            await viewModel.toggleSegment(index: index)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color(uiColor: SegmentationModel.colors[index]))
                    .opacity(viewModel.isSelected(index) ? 1 : 0.5)
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            switch requestStatus {
                case .success:
                    SegmentationMaskView(viewModel: viewModel)
                        .alert("More than 4 people in image. Using PersonSegmentationRequest instead.", isPresented: $isShowingDialog, actions: {
                            Button("OK", role: .cancel) { }
                        })
                        .onAppear() {
                            isShowingDialog = viewModel.showWarning
                        }
                case .loading:
                    ProgressView()
                case .failure:
                    Image(systemName: "exclamationmark.triangle.fill")
            }
        }.task {
            requestStatus = await viewModel.runSegmentationRequestOnImage(image)
        }
    }
}
