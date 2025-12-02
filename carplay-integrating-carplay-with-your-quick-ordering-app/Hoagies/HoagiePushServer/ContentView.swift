/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that the shop component uses to send updates.
*/

import SwiftUI

struct ContentView: View {
    
    @State var token: String = "<Get Token from the console logs of the Hoagies target>"
    
    var body: some View {
        Color.cornflowerBlue
        .ignoresSafeArea()
        .overlay {
            VStack {
                VStack {
                    Text("Welcome to the Hoagie Updates app!")
                    Text("🥖🧀🫕🥓🦃🐷🥩🥬🍅🧅🧂🌶️")
                }
                .font(.title)
                .padding()
                VStack {
                    VStack(alignment: .center) {
                        Text("FOR EMPLOYEES ONLY:")
                        Text("After logging the device token in Hoagies, you can update the order with it.")
                    }
                    .padding()
                    VStack(alignment: .leading) {
                        Text("Enter a token:")
                        TextField("Token", text: $token)
                        Button("Confirm order", action: {
                            Task {
                                do {
                                    try await APNS.sendLiveActivityContent(
                                        token: token,
                                        confirmed: true,
                                        preparing: false,
                                        ready: false,
                                        pickedUp: false,
                                        order: TestHoagieData.houseFavoriteOrder())
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        })
                        Button("Start preparing order", action: {
                            Task {
                                do {
                                    try await APNS.sendLiveActivityContent(
                                        token: token,
                                        confirmed: true,
                                        preparing: true,
                                        ready: false,
                                        pickedUp: false)
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        })
                        Button("Tap here when it's ready.", action: {
                            Task {
                                do {
                                    try await APNS.sendLiveActivityContent(
                                        token: token,
                                        confirmed: true,
                                        preparing: true,
                                        ready: true,
                                        pickedUp: false)
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        })
                        Button("Tap here when it's picked up.", action: {
                            Task {
                                do {
                                    try await APNS.sendLiveActivityContent(
                                        token: token,
                                        confirmed: true,
                                        preparing: true,
                                        ready: true,
                                        pickedUp: true)
                                } catch {
                                    print(error.localizedDescription)
                                }
                            }
                        })
                    }
                }
                .padding()
                .border(Color.cornflowerBlue, width: customBorderWidth)
            }
            .onAppear {
            }
        }
    }
}
struct HoagieServerContentState: Encodable {
    var isPickedUp: Bool
    var isReady: Bool
    var isPreparing: Bool
    var isConfirmed: Bool
}

import CryptoKit

extension Data {
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
