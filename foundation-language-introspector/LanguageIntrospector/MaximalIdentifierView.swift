/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The maximal identifier view.
*/

import SwiftUI

struct MaximalIdentifierView: View {
    let language: Locale.Language
    
    var body: some View {
        HStack {
            Text("दीर्घ कोड", comment: "Maximal Identifier")
                .subheadlineTextFormat()
            Spacer()
            Text(language.maximalIdentifier)
                .font(.body).monospaced()
        }
        .padding(.top, 20)
        .padding(.bottom, 5)
    }
}

#Preview {
    MaximalIdentifierView(language: Locale.Language(identifier: "hi"))
}
