/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The write review link view.
*/

import SwiftUI

struct WriteReviewLink: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button("Write a Review", action: requestReviewManually)
    }
    
    private func requestReviewManually() {
        // Replace the placeholder value below with the App Store ID for your app.
        // You can find the App Store ID in your app's product URL.
        let url = "https://apps.apple.com/app/id<#Your App Store ID#>?action=write-review"
        
        guard let writeReviewURL = URL(string: url) else {
            fatalError("Expected a valid URL")
        }
        
        openURL(writeReviewURL)
    }
}

#Preview {
    WriteReviewLink()
}
