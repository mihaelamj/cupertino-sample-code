/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that draws a hero's health level using a bar shape.
*/
import SwiftUI

struct HealthLevelShape: View {
    var level: Double
    @AppStorage("supercharged", store: EmojiRanger.emojiDefaults)
    var supercharged: Bool = EmojiRanger.herosAreSupercharged()
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let boxWidth = frame.width * (supercharged ? 1.0 : level)
            
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(Color.gray)
            
            RoundedRectangle(cornerRadius: 4)
                .frame(width: boxWidth)
                .foregroundStyle(Color.green)
        }
    }
}

#Preview(traits: .fixedLayout(width: 160, height: 20)) {
    HealthLevelShape(level: 0.8, supercharged: false)
}
