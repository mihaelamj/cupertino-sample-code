/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view of the watchOS app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        List {
            ForEach(EmojiRanger.allHeros) { hero in
                TableRow(hero: hero)
            }
        }
    }
}

struct TableRow: View {
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
