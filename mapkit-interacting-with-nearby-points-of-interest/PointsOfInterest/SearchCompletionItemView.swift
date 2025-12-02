/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view containing a single search completion from MapKit.
*/

import MapKit
import SwiftUI

struct SearchCompletionItemView: View {
    
    let completion: MKLocalSearchCompletion
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(AttributedString(completion.highlightedTitleStringForDisplay))
                .font(.headline)
            Text(AttributedString(completion.highlightedSubtitleStringForDisplay))
                .font(.subheadline)
        }
    }
}
