/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The step view.
*/

import StoreKit
import SwiftUI

struct StepView: View {
    let item: StepItem
    @Binding var path: [StepItem]
    
    /// An identifier for the three-step process the person completes before this app chooses to request a review.
    @AppStorage("processCompletedCount") var processCompletedCount = 0
    
    /// The most recent app version that prompts for a review.
    @AppStorage("lastVersionPromptedForReview") var lastVersionPromptedForReview = ""
    
    @Environment(\.requestReview) private var requestReview
    
    var body: some View {
        VStack(spacing: 8) {
            Button(item.localizedName, action: navigateNextPage)
                .font(.title2)
           
            Text(item.secondaryText)
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            guard item == .completed else {
                return
            }
            
            processCompletedCount += 1
        }
        .onChange(of: processCompletedCount) {
            guard let currentAppVersion = Bundle.currentAppVersion else {
                return
            }
            
            /*
                The lastVersionPromptedForReview property stores the version of the app that last prompts for a review.
                The app presents the rating and review request view if the person completed the three-step process at least four times and
                its current version is different from the version that last prompted them for review.
            */
            if processCompletedCount >= 4, currentAppVersion != lastVersionPromptedForReview {
                presentReview()
                    
                // The app already displayed the rating and review request view. Store this current version.
                lastVersionPromptedForReview = currentAppVersion
            }
        }
    }
    
    func navigateNextPage() {
        if item == .completed {
            print("Process completed \(processCompletedCount) time(s).")
        }
        
        if let destination = item.next() {
            path.append(destination)
        } else {
            path = []
        }
    }
    
    /// Presents the rating and review request view after a two-second delay.
    private func presentReview() {
        Task {
            // Delay for two seconds to avoid interrupting the person using the app.
            try await Task.sleep(for: .seconds(2))
            await requestReview()
        }
    }
}

#Preview {
    StepView(item: .first, path: .constant([.first]))
}
