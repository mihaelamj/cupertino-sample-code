/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of a backyard within the BackyardList.
*/

import SwiftUI

struct BackyardCell: View {
    let backyard: Backyard
    
    var body: some View {
        NavigationLink(value: backyard) {
            Group {
                Text(backyard.displayName)
                    .font(.callout)
                    .padding(.horizontal, 4)
                    .foregroundStyle(Color.primary.shadow(.drop(color: .black.opacity(0.7), radius: 2, y: 1)))
                    .padding(.vertical, 8)
                    .frame(minHeight: 85, alignment: .bottomLeading)
            }
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
        }
        .listRowBackground(BackyardImage(backyard: backyard))
    }
}

struct BackyardCell_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedBackyard: nil)
            .environmentObject(BackyardsData())
    }
}
