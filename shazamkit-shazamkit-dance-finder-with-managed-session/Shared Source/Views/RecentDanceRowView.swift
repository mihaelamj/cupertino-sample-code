/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View for each row of the list of previously danced songs.
*/

import ShazamKit
import SwiftUI

struct RecentDanceRowView: View {
    
    // MARK: View Constants
    private enum ViewConstants {
        static let rootHStackSpacing: CGFloat = 16.0
        static let artworkSize: CGFloat = 88.0
        static let artworkCornerRadius: CGFloat = 8.0
        static let artworkPadding: CGFloat = 20.0
        static let songDetailsVStackSpacing: CGFloat = 4.0
        static let danceFigureTrailingPadding: CGFloat = 5.0
        static let appleMusicLogo: String = "appleMusicLogo"
        static let dateTextTopPadding: CGFloat = 16.0
        static let rowDividerTopPadding: CGFloat = 24.0
        static let songDetailsTopPadding: CGFloat = 24.0
        static let rowDividerHeight: CGFloat = 3.0
        static let rowHeight: CGFloat = 138.0
        static let danceFigureImageName = "figure.dance"
        static let musicNoteImageName = "music.note"
        static let musicNoteImageWidth: CGFloat = 43.0
        static let musicNoteImageHeight: CGFloat = 41.0
        static let musicNoteImageBackgroundColor = Color(red: 116 / 255, green: 116 / 255, blue: 128 / 255, opacity: 0.18)
    }
    
    var mediaItem: SHMediaItem
    private var recognitionDate: String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d YYYY"
        return dateFormatter.string(from: mediaItem.creationDate ?? .now)
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: ViewConstants.rootHStackSpacing) {
            AsyncImage(url: mediaItem.artworkURL,
                       transaction: Transaction(animation: .easeInOut)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .clipShape(RoundedRectangle(cornerRadius: ViewConstants.artworkCornerRadius))
                case .empty, .failure(_):
                    ZStack {
                        RoundedRectangle(cornerRadius: ViewConstants.artworkCornerRadius)
                            .foregroundColor(ViewConstants.musicNoteImageBackgroundColor)
                        Image(systemName: ViewConstants.musicNoteImageName)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.musicNoteColor)
                            .frame(width: ViewConstants.musicNoteImageWidth, height: ViewConstants.musicNoteImageHeight)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: ViewConstants.artworkSize, height: ViewConstants.artworkSize)
            .padding(.leading, ViewConstants.artworkPadding)
            VStack(alignment: .leading, spacing: ViewConstants.songDetailsVStackSpacing) {
                Text(mediaItem.title ?? "")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(mediaItem.artist ?? mediaItem.subtitle ?? "")
                    .font(.body)
                    .foregroundStyle(.white)
                HStack(spacing: .zero) {
                    Image(systemName: ViewConstants.danceFigureImageName)
                        .font(.footnote)
                        .foregroundStyle(Color.appPrimary)
                        .padding(.trailing, ViewConstants.danceFigureTrailingPadding)
                    Text(recognitionDate)
                        .font(.footnote)
                        .foregroundStyle(Color.appGray)
                    Spacer()
                    Image(ViewConstants.appleMusicLogo)
                        .padding(.trailing)
                }
                .padding(.top, ViewConstants.dateTextTopPadding)
                Divider()
                    .overlay(Color.divider)
                    .frame(maxWidth: .infinity)
                    .frame(height: ViewConstants.rowDividerHeight)
                    .padding(.top, ViewConstants.rowDividerTopPadding)
            }
            .padding(.top, ViewConstants.songDetailsTopPadding)
        }
        .frame(height: ViewConstants.rowHeight)
        .background(Color.appSecondary)
        .listRowBackground(Color.appSecondary)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: .zero, leading: .zero, bottom: .zero, trailing: .zero))
    }
}

struct RecentDanceRowView_Previews: PreviewProvider {
    static var previews: some View {
        RecentDanceRowView(mediaItem: SHMediaItem(properties: [:]))
    }
}
