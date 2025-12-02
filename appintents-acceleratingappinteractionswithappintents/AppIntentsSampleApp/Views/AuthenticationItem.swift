/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that allows people to log in to and out of the app.
*/

import SwiftUI

struct AuthenticationItem: View {
    
    @Environment(AccountManager.self) private var accountManager
    
    private var statusText: some View {
        if accountManager.loggedIn {
            return Text("You are signed in")
        } else {
            return Text("You are signed out")
        }
    }
    
    var body: some View {
        HStack {
            HStack(alignment: .center) {
            #if !os(watchOS)
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30, alignment: .center)
                    .foregroundColor(.accentColor)
            #endif

                VStack(alignment: .leading) {
                    Text("Welcome!")
                      .font(.body)
                      .foregroundColor(.primary)
                     
                    statusText
                      .font(.subheadline)
                      .foregroundColor(.secondary)
                }
            }
            
            Spacer()

            let buttonTitle = accountManager.loggedIn ? "Sign Out" : "Sign In"
            Button(buttonTitle) {
                accountManager.loggedIn.toggle()
            }
            .buttonStyle(.bordered)
            .frame(alignment: .center)
        }
    }
}
