/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The visualization of `EmojiType`, which is tappable for selection.
*/

import SwiftUI

// The visulaization of EmojiType, which is tappable for selection
struct EmojiButton: View {
    let symptomIntensity: SymptomIntensity
    let isSelected: Bool

    var body: some View {
        Text("\(symptomIntensity.emoji)")
            .font(.system(size: 50))
            .shadow(color: isSelected ? symptomIntensity.color : .clear, radius: 10)
    }
}
