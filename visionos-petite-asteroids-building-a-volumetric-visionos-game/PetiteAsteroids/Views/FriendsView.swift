/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view showing the friends that the player collects.
*/

import SwiftUI

struct FriendsView: View {

    private static let friendsImageNames = [
        "RockFriend_Bowie",
        "RockFriend_Cavity",
        "RockFriend_Curvy",
        "RockFriend_Dottie",
        "RockFriend_Dubz",
        "RockFriend_Fleck",
        "RockFriend_Moon",
        "RockFriend_Rub",
        "RockFriend_Striped",
        "RockFriend_Wave",
        "RockFriend_Bowie",
        "RockFriend_Cavity"
    ]
    
    let rockFriendsCollectedMap: [String: Bool]

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {

            ForEach(0...5, id: \.self) { index in

                let rockFriendsCollectedMapKey = "RockPickup_\(index + 1)/\(Self.friendsImageNames[index])"
                let isCollected = rockFriendsCollectedMap[rockFriendsCollectedMapKey] ?? false

                FriendView(imageName: Self.friendsImageNames[index], isCollected: isCollected)
            }
                
          Image("Rock")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80)
            .hidden()
            .keyframeAnimator(initialValue: 0, repeating: true, content: { view, value in
              view
                .overlay {
                  Image(value > 0.1 ? "RockBlink" : "Rock")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80)
                }
            }, keyframes: { _ in
                LinearKeyframe(0, duration: 3.7)
                LinearKeyframe(1, duration: 0.4)
            })
            .background(
                VStack {
                    Spacer()
                    GroundShadow()
                }
            ).padding(.horizontal, 10)
            
            ForEach((6...11), id: \.self) { index in
                
                let rockFriendsCollectedMapKey = "RockPickup_\(index + 1)/\(Self.friendsImageNames[index])"
                let isCollected = rockFriendsCollectedMap[rockFriendsCollectedMapKey] ?? false

                FriendView(imageName: Self.friendsImageNames[index], isCollected: isCollected)
            }
            
        }
    }
}

private struct FriendView: View {
    
    let imageName: String
    let isCollected: Bool
    
    @State var appear = 0.0
    
    var body: some View {
        Image(imageName)
            .resizable()
            .renderingMode(isCollected ? .original : .template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.background)
            .background(
                VStack {
                    Spacer()
                    if isCollected {
                        GroundShadow()
                    }
                }
            )
            .scaleEffect(appear, anchor: .bottom)
            .onAppear {
                withAnimation(Animation.spring(duration: 0.3, bounce: 0.75).delay(TimeInterval(Float.random(in: 0.1..<0.4)))) {
                    appear = 1.0
                }
            }
    }
}

private struct GroundShadow: View {
    var body: some View {
        Ellipse()
            .frame(height: 3)
            .padding(.horizontal, 10)
            .foregroundStyle(.black)
            .blur(radius: 3, opaque: false)
    }
}

#Preview {
    FriendsView(rockFriendsCollectedMap: [
        "RockPickup_1/RockFriend_Bowie": false,
        "RockPickup_2/RockFriend_Cavity": true,
        "RockPickup_3/RockFriend_Curvy": false,
        "RockPickup_4/RockFriend_Dottie": true,
        "RockPickup_5/RockFriend_Dubz": false,
        "RockPickup_6/RockFriend_Fleck": false,
        "RockPickup_7/RockFriend_Moon": false,
        "RockPickup_8/RockFriend_Rub": false,
        "RockPickup_9/RockFriend_Striped": false,
        "RockPickup_10/RockFriend_Wave": false,
        "RockPickup_11/RockFriend_Bowie": true,
        "RockPickup_12/RockFriend_Cavity": false
    ])
        .frame(height: 80)
}
