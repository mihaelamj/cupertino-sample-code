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
                    .foregroundStyle(.secondary)
                    .background(Material.ultraThin, in: RoundedRectangle(cornerRadius: 7))
                    .padding(.vertical, 8)
                    .frame(minHeight: 85, alignment: .bottomLeading)
            }
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
            .overlay(alignment: .topTrailing) {
                Text("\(backyard.visitorScore)")
                    .frame(width: 25, height: 25)
                    .foregroundStyle(.secondary)
                    .background(.ultraThinMaterial, in: .circle)
                    .padding(.top, 5)
            }
        }
        .listRowBackground(BackyardImage(backyard: backyard))
        .environment(\.colorScheme, .light)
    }
}

struct BackyardCell_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(selectedBackyard: nil)
            .environmentObject(BackyardsData())
    }
}
