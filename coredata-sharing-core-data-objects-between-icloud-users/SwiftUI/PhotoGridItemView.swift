/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that manages a grid item.
*/

import SwiftUI
import CoreData

struct PhotoGridItemView: View {
    @ObservedObject var photo: Photo
    var itemSize: CGSize
    @State private var isHovering = false
    private let persistenceController = PersistenceController.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            /**
             Show the thumbnail image, or a placeholder if the thumbnail data doesn't exist.
             */
            if let data = photo.thumbnail?.data, let thumbnail = UIImage(data: data) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: itemSize.width, height: itemSize.height)
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 30))
                    .frame(width: itemSize.width, height: itemSize.height)
            }
            topLeftButton()
        }
        .frame(width: itemSize.width, height: itemSize.height)
        .background(Color.gridItemBackground)
        #if os(macOS)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(.blue, lineWidth: isHovering ? 2 : 0)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        #endif
    }
    
    @ViewBuilder
    private func topLeftButton() -> some View {
        if persistenceController.sharedPersistentStore.contains(manageObject: photo) {
            Image(systemName: "person.2.circle")
                .foregroundColor(.green)
        }
    }
}
