/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view representing a video in the navigation sidebar.
*/

import SwiftUI

struct VideoSelector: View {
    @ObservedObject var session: LocalSession
    var onDelete: () -> Void
    
    var body: some View {
        let selectable = session.state != .remote

        let view = NavigationLink(value: selectable ? session : nil) {
            HStack {
                HStack {
                    Thumbnail(localSession: session)
                    SessionDescription(session: session, style: .short)
                }
                
                if session.essential {
                    Spacer()
                    Circle()
                        .fill(.green)
                        .frame(width: 10, alignment: (.trailing))
                }
            }
        }
        .deleteDisabled(session.state != .downloaded)
        #if os(macOS)
        .swipeActions(edge: .trailing) {
            if session.state == .downloaded {
                Button(role: .destructive, action: self.onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        #endif

        if selectable {
            view
        } else {
            view.foregroundColor(.gray)
                .disabled(true)
        }
    }
}

struct VideoSelector_Previews: PreviewProvider {
    @State static private var sessionManager = SessionManager()

    static var previews: some View {
        NavigationSplitView {
            if let session = sessionManager.sessions.first {
                VideoSelector(session: session) {}
            } else {
                ProgressView()
            }
        } detail: {
            Text("Detail!")
        }
    }
}
