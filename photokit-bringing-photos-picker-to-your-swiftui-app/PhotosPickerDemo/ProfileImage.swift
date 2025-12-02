/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The profile image that reflects the selected item state.
*/

import SwiftUI
import PhotosUI

struct ProfileImage: View {
	let imageState: ProfileModel.ImageState
	
	var body: some View {
		switch imageState {
		case .success(let image):
			image.resizable()
		case .loading:
			ProgressView()
		case .empty:
			Image(systemName: "person.fill")
				.font(.system(size: 40))
				.foregroundColor(.white)
		case .failure:
			Image(systemName: "exclamationmark.triangle.fill")
				.font(.system(size: 40))
				.foregroundColor(.white)
		}
	}
}

struct CircularProfileImage: View {
	let imageState: ProfileModel.ImageState
	
	var body: some View {
		ProfileImage(imageState: imageState)
            .scaledToFill()
			.clipShape(Circle())
			.frame(width: 100, height: 100)
			.background {
				Circle().fill(
					LinearGradient(
						colors: [.yellow, .orange],
						startPoint: .top,
						endPoint: .bottom
					)
				)
			}
	}
}

struct EditableCircularProfileImage: View {
	@ObservedObject var viewModel: ProfileModel
	
	var body: some View {
		CircularProfileImage(imageState: viewModel.imageState)
			.overlay(alignment: .bottomTrailing) {
				PhotosPicker(selection: $viewModel.imageSelection,
							 matching: .images,
							 photoLibrary: .shared()) {
					Image(systemName: "pencil.circle.fill")
						.symbolRenderingMode(.multicolor)
						.font(.system(size: 30))
						.foregroundColor(.accentColor)
				}
				.buttonStyle(.borderless)
			}
	}
}
