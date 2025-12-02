/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The adventure activity content.
*/

import SwiftUI
import WidgetKit

#if canImport(ActivityKit)

struct AdventureLiveActivityContent: View {
    let hero: EmojiRanger
    let isStale: Bool
    let contentState: AdventureAttributes.ContentState
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                LiveActivityAvatarView(hero: hero)
                
                Spacer()
                
                OneLineStatsView(hero: hero, isStale: isStale)
            }
            
            HealthBar(currentHealthLevel: contentState.currentHealthLevel)
            
            EventDescriptionView(hero: hero, contentState: contentState)
        }
        .foregroundStyle(Color.textColor)
    }
}

struct AdventureLiveActivityView: View {
    let hero: EmojiRanger
    let isStale: Bool
    let contentState: AdventureAttributes.ContentState
    
    public var body: some View {
        AdventureLiveActivityContent(
            hero: hero,
            isStale: isStale,
            contentState: contentState
        )
        .padding()
    }
}

struct LiveActivityAvatarView: View {
    
    let hero: EmojiRanger
    
    var body: some View {
        Link(destination: hero.url) {
            HStack {
                Avatar(hero: hero, includeBackground: true)
                    .frame(minWidth: 25, minHeight: 25)
                    .aspectRatio(1, contentMode: .fit)
                
                Text(hero.name)
                    .layoutPriority(100)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(height: 30)
    }
}

struct HealthBar: View {
    
    let currentHealthLevel: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.red, Color.white)
                .minimumScaleFactor(0.5)
            
            HealthLevelShape(level: currentHealthLevel)
                .frame(height: 10)
            
            Text("\(Int(currentHealthLevel * 100))")
                .minimumScaleFactor(0.5)
        }
        .frame(height: 16)
    }
}

struct EventDescriptionView: View {
    
    let hero: EmojiRanger
    let contentState: AdventureAttributes.ContentState
    
    var body: some View {
        
        Text(contentState.eventDescription)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .font(.headline)
    }
}

struct OneLineStatsView: View {
    
    let hero: EmojiRanger
    let isStale: Bool
    
    var body: some View {
        Group {
            if isStale {
                Text("Outdated \(Image(systemName: "clock.badge.exclamationmark.fill")) ")
                    .padding(4)
                    .background(ContainerRelativeShape().fill(Color.red))
            } else {
                Text("Level: \(hero.level)    XP: \(hero.exp)")
            }
        }
        .font(.caption)
        .multilineTextAlignment(.center)
        .frame(height: 30)
    }
}

struct TwoLineStatsView: View {
    
    let hero: EmojiRanger
    let isStale: Bool
    
    var body: some View {
        Group {
            if isStale {
                Text("Outdated \(Image(systemName: "clock.badge.exclamationmark.fill")) ")
                    .padding(4)
                    .background(ContainerRelativeShape().fill(Color.red))
            } else {
                Text("Level: \(hero.level)")
                    .padding([.trailing], 4)
                Text("XP: \(hero.exp)")
            }
        }
        .font(.caption)
    }
}

#Preview {
    AdventureLiveActivityView(hero: .panda, isStale: false, contentState:
            .init(currentHealthLevel: 0.5, eventDescription: "sampple description", supercharged: false))
}

#endif
