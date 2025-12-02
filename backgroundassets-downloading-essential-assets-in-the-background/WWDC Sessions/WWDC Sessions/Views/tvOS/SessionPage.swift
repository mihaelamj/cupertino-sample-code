/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A page that shows the details of a WWDC session.
*/

import AVKit
import SwiftUI

struct SessionPage: View {
    
    let session: LocalSession
    private let player = AVPlayer()
    
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            if let image = session.thumbnailImage {
                Image(uiImage: UIImage(cgImage: image))
                    .resizable()
                    .ignoresSafeArea()
                    .scaledToFill()
            }
            VStack {
                HStack {
                    Text(session.title)
                        .font(.title2)
                        .bold()
                        .padding(5)
                        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
                Spacer()
                HStack(alignment: .top) {
                    VStack {
                        NavigationLink {
                            VideoPlayer(player: player)
                                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                                .onAppear {
                                    player.replaceCurrentItem(with: AVPlayerItem(url: session.fileURL))
                                    player.play()
                                }
                                .onDisappear {
                                    player.pause()
                                }
                        } label: {
                            Label("Play", systemImage: "play")
                                .frame(maxWidth: .infinity)
                        }
                        Button(role: .destructive) {
                            sessionManager.delete(session)
                            dismiss()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .symbolVariant(.fill)
                    .frame(maxWidth: 300)
                    SessionDescription(session: session, style: .detailed)
                    Spacer()
                }
                .padding(30)
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(50)
        }
    }
    
}
