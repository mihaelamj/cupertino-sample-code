/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a list of heroes sorted by their health level.
*/
import SwiftUI

struct AllCharactersView: View {
    
    let heros: [EmojiRanger]
    
    init(heros: [EmojiRanger]? = EmojiRanger.allHeros) {
        self.heros = heros ?? EmojiRanger.allHeros
    }
    
    var body: some View {
        VStack(spacing: 48) {
            ForEach(heros.sorted { $0.healthLevel > $1.healthLevel }, id: \.self) { hero in
                Link(destination: hero.url) {
                    HStack {
                        Avatar(hero: hero)
                        VStack(alignment: .leading) {
                            Text(hero.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Level \(hero.level)")
                                .foregroundStyle(.white)
                            HealthLevelShape(level: hero.healthLevel)
                                .frame(height: 10)
                        }
                    }
                }
                .padding()
            }
        }
        .background {
            Color.gameBackgroundColor
        }
    }
}

#Preview {
    AllCharactersView(heros: nil)
}
