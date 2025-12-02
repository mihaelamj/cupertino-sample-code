/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The character direction view.
*/

import SwiftUI

struct CharacterDirectionView: View {
    let language: Locale.Language
    
    var body: some View {
        HStack {
            Text("अक्षरों की दिशा", comment: "Character Direction")
                .subheadlineTextFormat()
            Spacer()
            characterDirectionView
                .font(.body)
        }
        .padding(.bottom, 5)
    }
    
    private var characterDirectionView: some View {
        switch language.characterDirection {
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
    CharacterDirectionView(language: Locale.Language(identifier: "hi"))
}
