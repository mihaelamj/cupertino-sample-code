/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that prompts for photo selection and displays the original image.
*/
import Foundation
import PhotosUI
import SwiftUI

struct PhotoSelectionView: View {
    @StateObject var viewModel = PhotoSelectionModel()
    
    // The view for each state of image selection.
    struct SelectedImageView: View {
        let imageState: PhotoSelectionModel.ImageState
        var body: some View {
            switch imageState {
            case .success(let image):
                image.resizable()
            case .loading:
                ProgressView()
            case .noneselected:
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            case .failure:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Spacer()
            SelectedImageView(imageState: viewModel.imageState)
                .scaledToFill()
                .frame(width: 300, height: 300)
                .background {
                    LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
                }
                .cornerRadius(8.0)
            PhotosPicker(selection: $viewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                Image(systemName: "photo.stack")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                Text("Select Photo")
            }
            Spacer()
            NavigationLink("Run Person Segmentation") {
                if viewModel.image != nil {
                    SegmentationResultsView(image: viewModel.image!)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.image == nil)
        }
    }
}

