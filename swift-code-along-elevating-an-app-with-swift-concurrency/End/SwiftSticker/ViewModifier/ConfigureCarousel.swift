/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view extension that provides configuration for a carousel
  interface with paging behavior and a toolbar.
*/

import SwiftUI
import PhotosUI

extension View {
    func configureCarousel(
        _ viewModel: StickerViewModel,
        sheetPresented: Binding<Bool>
    ) -> some View {
        self
            .contentMargins(32)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItemGroup {
                    PhotosPicker(
                        selection: viewModel.photosPickerSelection,
                        matching: .images,
                        preferredItemEncoding: .current,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "plus")
                    }

                    Button {
                        sheetPresented.wrappedValue.toggle()
                    } label: {
                        Image(systemName: "arrow.up.document")
                    }
                }
            }
    }
}
