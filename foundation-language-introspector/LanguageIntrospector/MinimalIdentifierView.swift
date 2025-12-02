/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The minimal identifier view.
*/

import SwiftUI

struct MinimalIdentifierView: View {
    let language: Locale.Language
    
    var body: some View {
        HStack {
            Text("ह्रस्व कोड", comment: "Minimal Identifier")
                .subheadlineTextFormat()
            Spacer()
            Text(language.minimalIdentifier)
                .font(.body).monospaced()
        }
        .padding(.bottom, 5)
    }
}

#Preview {
    MinimalIdentifierView(language: Locale.Language(identifier: "hi"))
}
