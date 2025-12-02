/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Today's summary view of a backyard.
*/

import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var backyard: Backyard
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Last Visitor")
                        .font(.caption2.smallCaps())
                    Text("Cedar Waxwing")
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image("Petrel")
            }
            .padding(.bottom)
            BackyardSummary(score: backyard.visitorScore)
        }
        .scenePadding(.horizontal)
        .listRowBackground(Color.clear)
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BackyardView(backyard: .preview)
        }
    }
}
