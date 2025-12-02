/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that graphs workout data.
*/

import SwiftUI

/// A view that draws the graph based off an array of data points for an activity.
struct PastWorkoutsGraph: View {
    
    // MARK: - Properties
    
    var data: [ActivityData] = ActivityData.data
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Text("Miles Ran")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: Self.graphSpacing) {
                GeometryReader { proxy in
                    CurvedFilledLine(data: data, frame: proxy.frame(in: .local))
                }
                .overlay {
                    overlay
                }
                xAxis
            }
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.vertical, Self.verticalSpacing)
            .background {
                RoundedRectangle(cornerRadius: Self.backgroundRadius, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .standardShadow()
            }
        }
    }
    
    private var overlay: some View {
        VStack {
            let maxString = String(format: "%.2f", data.map { $0.milesRan }.max() ?? 0)
            Text("\(maxString) miles")
                .font(.caption)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var xAxis: some View {
        HStack {
            ForEach(data, id: \.self) { datum in
                Text(datum.day)
                    .font(.caption)
                if datum != data.last {
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Constants
    
    private static let graphSpacing: CGFloat = 15
    private static let horizontalPadding: CGFloat = 20
    private static let verticalSpacing: CGFloat = 25
    private static let backgroundRadius: CGFloat = 25
}

// MARK: - Activity data

/// An object that holds the miles ran on a particular day.
struct ActivityData: Hashable {
    
    /// Hardcoded `ActivityData` for previous workouts.
    static var data: [ActivityData] = [
        ActivityData(milesRan: 1.13, day: "Sun"),
        ActivityData(milesRan: 2.13, day: "Mon"),
        ActivityData(milesRan: 1.02, day: "Tues"),
        ActivityData(milesRan: 3.49, day: "Wed"),
        ActivityData(milesRan: 0.3, day: "Thurs"),
        ActivityData(milesRan: 1.03, day: "Fri"),
        ActivityData(milesRan: 2.21, day: "Sat")
    ]
    
    init(milesRan: Double, day: String) {
        self.milesRan = milesRan
        self.day = day
    }
    
    let milesRan: Double
    let day: String
}
