/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The adventure activity configuration.
*/

import WidgetKit
import SwiftUI

struct AdventureActivityConfiguration: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AdventureAttributes.self) { context in
            // Create the presentation that appears on the Lock Screen and as a
            // banner on the Home Screen of devices that don't support the
            // Dynamic Island.
            AdventureLiveActivityView(
                hero: context.attributes.hero,
                isStale: context.isStale,
                contentState: context.state
            )
            .activityBackgroundTint(Color.liveActivityBackground.opacity(0.25))
        } dynamicIsland: { context in
            // Create the presentations that appear in the Dynamic Island.
            DynamicIsland {
                // Create the expanded presentation.
                expandedContent(
                    hero: context.attributes.hero,
                    contentState: context.state,
                    isStale: context.isStale
                )
            } compactLeading: {
                // Create the compact leading presentation.
                Avatar(hero: context.attributes.hero, includeBackground: true)
                    .accessibilityLabel("The avatar of \(context.attributes.hero.name).")
            } compactTrailing: {
                // Create the compact trailing presentation.
                ProgressView(value: context.state.currentHealthLevel, total: 1) {
                    let healthLevel = Int(context.state.currentHealthLevel * 100)
                    Text("\(healthLevel)")
                        .accessibilityLabel("Health level at \(healthLevel) percent.")
                }
                .progressViewStyle(.circular)
                .tint(context.state.currentHealthLevel <= 0.2 ? Color.red : Color.green)
            } minimal: {
                // Create the minimal presentation.
                ProgressView(value: context.state.currentHealthLevel, total: 1) {
                    Avatar(hero: context.attributes.hero, includeBackground: false)
                        .accessibilityLabel("The avatar of \(context.attributes.hero.name).")
                }
                .progressViewStyle(.circular)
                .tint(context.state.currentHealthLevel <= 0.2 ? Color.red : Color.green)
            }
            
        }
    }
    
    @DynamicIslandExpandedContentBuilder
    private func expandedContent(hero: EmojiRanger,
                                 contentState: AdventureAttributes.ContentState,
                                 isStale: Bool) -> DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.leading) {
            LiveActivityAvatarView(hero: hero)
        }
        
        DynamicIslandExpandedRegion(.trailing) {
            TwoLineStatsView(hero: hero, isStale: isStale)
        }
        
        DynamicIslandExpandedRegion(.bottom) {
            
            HealthBar(currentHealthLevel: contentState.currentHealthLevel)
            
            EventDescriptionView(
                hero: hero,
                contentState: contentState
            )
        }
    }
}
