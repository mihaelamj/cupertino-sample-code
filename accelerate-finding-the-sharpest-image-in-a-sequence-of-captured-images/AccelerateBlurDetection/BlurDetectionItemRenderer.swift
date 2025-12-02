/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The blur detection result item renderer.
*/

import AVFoundation
import SwiftUI

struct BlurDetectionItemRenderer: View {
    
    var item: BlurDetectionResult

    var body: some View {
        VStack {
            HStack {
                Text("Score: \(item.score)")
                    .bold()
                
                Spacer()
                
                Text("Index: \(item.index)")
            }
            
            HStack {
                Image(decorative: item.image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Image(decorative: item.laplacianImage, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}
