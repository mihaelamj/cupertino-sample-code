/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how add an action button and then redirect to a specific URL.
*/


import SwiftUI
import TipKit

struct PasswordResetTip: Tip {
    var title: Text {
        Text("Need Help?")
    }

    var message: Text? {
        Text("Do you need help logging in to your account?")
    }

    var image: Image? {
        Image(systemName: "lock.shield")
    }

    var actions: [Action] {
        // Define a reset password button.
        Action(id: "reset-password", title: "Reset Password")
        // Define a FAQ button.
        Action(id: "faq", title: "View our FAQ")
    }
}

struct PasswordResetView: View {
    @Environment(\.openURL)
    var openURL

    // Create an instance of your tip content.
    let passwordResetTip = PasswordResetTip()

    var body: some View {
        VStack(spacing: 20) {
            Text("Use action buttons to link to more options. In this example, two actions buttons are provided. One takes the user to the Reset Password feature. The other sends them to an FAQ page.")
            
            // Place your tip near the feature you want to highlight.
            TipView(passwordResetTip, arrowEdge: .bottom) { action in
                // Define the closure that executes when someone presses the reset button.
                if action.id == "reset-password", let url = URL(string: "https://iforgot.apple.com") {
                    openURL(url) { accepted in
                        print(accepted ? "Success Reset" : "Failure")
                    }
                }

                // Define the closure that executes when someone presses the FAQ button.
                if action.id == "faq", let url = URL(string: "https://appleid.apple.com/faq") {
                    openURL(url) { accepted in
                        print(accepted ? "Success FAQ" : "Failure")
                    }
                }
            }
            Button("Login") {
                // Perform login action.
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Password reset")
    }
}

#Preview {
    PasswordResetView()
}

