/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the list of available characters.
*/
import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @State private var selection: EmojiRanger?
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(EmojiRanger.allHeros, id: \.self) { hero in
                NavigationLink(value: hero) {
                    TableRow(hero: hero)
                }
            }
            .onAppear {
                // Check for the most recently selected character.
                if let hero = try? EmojiRanger.getLastSelectedHero() {
                    print("Last character selection: \(hero)")
                }
            }
            .navigationBarTitle("Your Characters")
            .onOpenURL(perform: { (url) in
                if let match = EmojiRanger.allHeros.compactMap({ hero in
                    url == hero.url ? hero : nil
                }).first {
                    navigationPath = NavigationPath([match])
                }
            })
            .navigationDestination(for: EmojiRanger.self) { hero in
                DetailView(hero: hero)
            }
        }
    }
}

private struct TableRow: View {
    let hero: EmojiRanger
    var body: some View {
        HStack {
            Avatar(hero: hero)
            HeroNameView(hero)
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
