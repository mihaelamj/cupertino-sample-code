/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The adventure view model.
*/
import ActivityKit
import Foundation
import os.log

extension AdventureViewModel {
    
    typealias ServerManager = AdventureViewModel
    
    func startActivity(hero: EmojiRanger) throws {
        let adventure = AdventureAttributes(hero: hero)
        let initialState = AdventureAttributes.ContentState(
            currentHealthLevel: hero.healthLevel,
            eventDescription: "Adventure has begun!",
            supercharged: EmojiRanger.herosAreSupercharged()
        )
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let activity = try Activity.request(
                attributes: adventure,
                content: .init(state: initialState, staleDate: nil),
                pushType: .token
            )
            
            //        let pushToken = activity.pushToken // Returns nil.
            
            Task {
                for await pushToken in activity.pushTokenUpdates {
                    let pushTokenString = pushToken.reduce("") {
                        $0 + String(format: "%02x", $1)
                    }
                    
                    Logger().log("New push token: \(pushTokenString)")
                    
                    try await self.sendPushToken(hero: hero, pushTokenString: pushTokenString)
                }
            }
        }
    }
    
    func printEncoded() {
        let contentState = AdventureAttributes.ContentState(
            currentHealthLevel: 0.941,
            eventDescription: "Power Panda found a sword!",
            supercharged: EmojiRanger.herosAreSupercharged()
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let json = try! encoder.encode(contentState)
        Logger().log("\(String(data: json, encoding: .utf8)!)")
    }
    
    func showWarningBadge(_ shouldShow: Bool) {
        
    }
    
    func observeFrequentUpdate() {
        Task {
            for await isEnabled in ActivityAuthorizationInfo().frequentPushEnablementUpdates {
                self.showWarningBadge(!isEnabled)
            }
        }
    }
    
    func updateAdventureView(content: ActivityContent<AdventureAttributes.ContentState>) {
        
    }
    
    func observeActivityUpdates(_ activity: Activity<AdventureAttributes>) {
        // Observe updates for ongoing Live Activities.
        Task {
            for await content in activity.contentUpdates {
                self.updateAdventureView(content: content)
            }
        }
    }
}
