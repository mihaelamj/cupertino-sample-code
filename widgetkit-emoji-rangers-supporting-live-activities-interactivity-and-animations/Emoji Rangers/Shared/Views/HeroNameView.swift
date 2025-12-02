/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a hero's name.
*/
import SwiftUI

struct HeroNameView: View {
    private let hero: EmojiRanger
    let includeDetail: Bool
    
    init(_ hero: EmojiRanger?, includeDetail: Bool = true) {
        self.hero = hero ?? EmojiRanger.spouty
        self.includeDetail = includeDetail
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(hero.name)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.2)
            if includeDetail {
                Text("Level \(hero.level)")
                    .minimumScaleFactor(0.2)
                Text("\(hero.exp) XP")
                    .minimumScaleFactor(0.2)
            }
        }
    }
}

#Preview {
    HeroNameView(nil, includeDetail: true)
}
