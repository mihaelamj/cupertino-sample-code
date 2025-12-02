/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The blur detection results list.
*/

import SwiftUI

struct BlurDetectorResultsList: View {
    let results: [BlurDetectionResult]

    var body: some View {
        List(self.results, id: \.index) { item in
            BlurDetectionItemRenderer(item: item)
        }
    }
}

