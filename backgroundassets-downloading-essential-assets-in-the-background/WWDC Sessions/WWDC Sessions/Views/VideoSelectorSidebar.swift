/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view representing the navigation sidebar.
*/

import SwiftUI

struct VideoSelectorSidebar: View {
    @EnvironmentObject var sessionManager: SessionManager
    @Binding var selections: Set<LocalSession>
    
    var body: some View {
        List(selection: $selections) {
            selectors
        }
        .toolbar(content: toolbarContent)
        #if os(macOS)
        .navigationSplitViewColumnWidth(ideal: 360)
        #endif
    }
    
    var selectors: some View {
        ForEach(self.sessionManager.sessions) { session in
            VideoSelector(session: session) {
                self.delete(session: session)
            }
        }
        #if os(iOS)
        .onDelete { indices in
            let sessions = indices.map { self.sessionManager.sessions[$0] }
            for session in sessions {
                self.delete(session: session)
            }
        }
        #endif
    }
    
    private func delete(session: LocalSession) {
        self.selections.remove(session)
        self.sessionManager.delete(session)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        #if os(iOS)
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            refreshButton
        }
        #else
        ToolbarItemGroup(placement: .navigation) {
            refreshButton
        }
        #endif
    }

    var refreshButton: some View {
        Button {
            self.sessionManager.refreshManifest()
        } label: {
            Label("Refresh", systemImage: "arrow.counterclockwise")
        }
    }
}

struct VideoSelectorSidebar_Previews: PreviewProvider {
    struct Preview: View {
        @State private var selections: Set<LocalSession> = []
        @StateObject private var sessionManager = SessionManager()
        
        var body: some View {
            VideoSelectorSidebar(selections: $selections)
                .environmentObject(sessionManager)
        }
    }
    
    static var previews: some View {
        NavigationSplitView {
            Preview()
        } detail: {
            Text("Detail!")
        }
    }
}
