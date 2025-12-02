/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The reset button view.
*/

import SwiftUI

struct ResetButton: View {
    /// An identifier for the three-step process the person completes before this app chooses to request a review.
    @AppStorage("processCompletedCount") var processCompletedCount = 0
    
    /// The most recent app version that prompts for a review.
    @AppStorage("lastVersionPromptedForReview") var lastVersionPromptedForReview = ""
     
    var body: some View {
        Button("Reset Sample", action: resetSample)
    }
    
    /// Resets the counter and the most recently checked app version.
    private func resetSample() {
        processCompletedCount = 0
        lastVersionPromptedForReview = ""
        
        print("All checks have been reset")
    }
}

#Preview {
    ResetButton()
}
