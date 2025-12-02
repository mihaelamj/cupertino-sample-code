/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view for the SessionDescription that goes into the navigation view.
*/

import Foundation
import SwiftUI

struct SessionDescription: View {
    @ObservedObject var session: LocalSession
    var style: Style

    enum Style {
        case short
        case detailed
    }

    var body: some View {
        switch self.style {
        case .short:
            shortDescription
        case .detailed:
            detailedDescription
        }
    }

    var shortDescription: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(session.year.description)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            Text(session.title)
                .font(.headline)
            Text(session.authors.joined(separator: ", "))
                .font(.callout)
        }
    }

    var detailedDescription: some View {
        VStack {
            #if !os(tvOS)
            Text(session.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            #endif
            Text(session.description)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
            Text(session.authors.joined(separator: ", "))
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct SessionDescription_Previews: PreviewProvider {
    @State static private var sessionManager = SessionManager()
    static var previews: some View {
        if let session = sessionManager.sessions.first {
            VStack {
                Text("-- Short --")
                SessionDescription(session: session, style: .short)
                Text("-- Detailed ---")
                SessionDescription(session: session, style: .detailed)
            }
        } else {
            ProgressView()
        }
    }
}
