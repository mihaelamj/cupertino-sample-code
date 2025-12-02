/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a featured image of a trail, with a small amount of additional detail.
*/

import SwiftUI

struct TrailInfoView: View {
    var trail: Trail
    var includeConditions = false
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Image(trail.featuredImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
                
                VStack {
                    Text(trail.name)
                        .font(.title)
                    Text(trail.regionDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if includeConditions {
                        Text(trail.currentConditions)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
    }
}
