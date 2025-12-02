/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Wrapper around SessionManager for use in previews that require a Binding<LocalSession>.
*/

import Foundation
import SwiftUI

class PreviewSessionManager: ObservableObject {
    @Published var sessionManager = SessionManager()

    var session: Binding<LocalSession?> {
        Binding { [session = self.sessionManager.sessions.first] in
            return session
        } set: { _ in

        }
    }
}
