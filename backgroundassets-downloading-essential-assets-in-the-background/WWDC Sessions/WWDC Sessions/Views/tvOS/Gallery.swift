/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A gallery of available WWDC sessions.
*/

import SwiftUI

struct Gallery: View {
    
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        HStack {
            Text("WWDC Sessions")
                .font(.title)
                .bold()
            Spacer()
        }
        if sessionManager.sessions.isEmpty {
            Spacer()
            HStack {
                Spacer()
                Text("Refresh the manifest to see available WWDC sessions.")
                    .font(.callout)
                Spacer()
            }
            Spacer()
        } else {
            ScrollView(.horizontal) {
                LazyHStack {
                    ForEach(sessionManager.sessions) { session in
                        VStack {
                            Group {
                                switch session.state {
                                case .downloaded:
                                    NavigationLink {
                                        SessionPage(session: session)
                                    } label: {
                                        Thumbnail(localSession: session)
                                    }
                                case .remote:
                                    Button {
                                        sessionManager.startDownload(of: session)
                                    } label: {
                                        Thumbnail(localSession: session)
                                    }
                                }
                            }
                            .frame(height: thumbnailHeight)
                            Text(session.title)
                                .lineLimit(2, reservesSpace: true)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: thumbnailWidth)
                    }
                }
            }
            .scrollClipDisabled()
            .buttonStyle(.card)
        }
        HStack {
            Spacer()
            VStack {
            Button {
                sessionManager.refreshManifest()
            } label: {
                Label("Refresh Manifest", systemImage: "arrow.counterclockwise")
            }
            .padding(.bottom)
            }
            Spacer()
        }
    }
    
}

#Preview {
    Gallery()
}
