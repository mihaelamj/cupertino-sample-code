/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The backyard summary within the today view.
*/

import SwiftUI

struct BackyardSummary: View {
    var score: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Summary")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            HStack {
                HStack {
                    Image(systemName: "bird.fill")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    Text("25")
                        .font(.system(size: 35))
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "ant.fill")
                            .foregroundStyle(.purple)
                        Text("**149**")
                    }
                    HStack {
                        Image(systemName: "minus.plus.batteryblock")
                            .foregroundStyle(.yellow)
                        Text("**OK**")
                    }
                }
            }
        }
    }
}
