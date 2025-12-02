/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for the settings of a recipe, which allows someone to select an image
  from the photos library to show in the background of a certain recipe.
*/

import SwiftUI
import PhotosUI

struct RecipeSettings: View {
    @Bindable var recipe: Recipe

    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Form {
            HStack(alignment: .center) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Recipe Image")
                }

                Spacer()

                ImageWithPlaceholder(recipe.image) {
                    ZStack {
                        Color.gray
                        Image(systemName: "photo.fill")
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else {
                    return
                }

                let image = try? await selectedPhoto.loadTransferable(type: Image.self)
                recipe.image = try? await image?.exported(as: .image)
            }
        }
    }
}
