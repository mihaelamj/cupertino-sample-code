/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows the details of a character.
*/
import SwiftUI
import ActivityKit
import BackgroundTasks

struct DetailView: View {
    
    let hero: EmojiRanger
    
    @AppStorage("supercharged", store: UserDefaults(suiteName: EmojiRanger.appGroup))
    var supercharged: Bool = EmojiRanger.herosAreSupercharged()
    
    var body: some View {
        ScrollView {
            ZStack {
                Color.appBackground.edgesIgnoringSafeArea(.all)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 0) {
                        AvatarView(hero)
                            .frame(width: 170, height: 170, alignment: .leading)
                            .padding()
                        
                        if #available(iOS 17.0, *) {
                            Button(intent: SuperCharge()) {
                                Text("⚡️")
                                    .lineLimit(1)
                            }
                            .padding()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.gameBackground))
                    Text("When the timer ends, \(hero.name) will be back to full health and the next wave of enemies will attack. Place the Game Status widget on your Home screen to be prepared.")
                        .font(.callout)
                        .padding()
                        .multilineTextAlignment(.leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.gameBackground))
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About \(hero.name)")
                            .font(.title)
                        Text("\(hero.bio)")
                            .font(.title2)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.gameBackground))
                }
                .padding()
                .foregroundStyle(.white)
            }
            Divider()
            AdventureView(hero: hero)
        }
    }
}

#Preview {
    DetailView(hero: .spouty)
}
