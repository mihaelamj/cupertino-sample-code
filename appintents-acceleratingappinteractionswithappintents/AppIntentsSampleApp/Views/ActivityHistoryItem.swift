/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view displaying the details of an individual's tracked activity.
*/

import SwiftUI

struct ActivityHistoryItem: View {
    
    let activity: Activity
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(activity.style.localizedStringResource)
                
                let endedString = activity.end?.formatted() ?? "Ongoing"
                Text("\(activity.start.formatted()) - \(endedString)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        } icon: {
            Image(systemName: activity.style.symbol)
        }
    }
}
