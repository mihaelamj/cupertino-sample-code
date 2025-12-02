/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The line layout direction view.
*/

import SwiftUI

struct LineLayoutDirectionView: View {
    let language: Locale.Language
    
    var body: some View {
        HStack {
            Text("पंक्तियों की दिशा", comment: "Line Layout Direction")
                .subheadlineTextFormat()
            Spacer()
            lineLayoutDirectionView
                .font(.body)
        }
        .padding(.bottom, 5)
    }
    
    private var lineLayoutDirectionView: some View {
        switch language.lineLayoutDirection {
        case .leftToRight:
            Text("बाएँ से दाएँ", comment: "Left to Right")
        case .rightToLeft:
            Text("दाएँ से बाएँ", comment: "Right to Left")
        case .topToBottom:
            Text("ऊपर से नीचे", comment: "Top to Bottom")
        case .bottomToTop:
            Text("नीचे से ऊपर", comment: "Bottom to Top")
        default:
            Text("अज्ञात", comment: "Unknown")
        }
    }
}

#Preview {
    LineLayoutDirectionView(language: Locale.Language(identifier: "hi"))
}
