/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays workout data.
*/

import SwiftUI

/// The top-level view the app displays during a workout. It displays metrics about the workout.
struct WorkoutDataView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: WorkoutViewModel
    
    private var hours: Int {
        viewModel.progressTime / 3600
    }
    
    private var minutes: Int {
        (viewModel.progressTime % 3600) / 60
    }
    
    private var seconds: Int {
        viewModel.progressTime % 60
    }
    
    private var distanceString: String {
        let distanceInMiles = viewModel.distance.value * 0.000_621
        return String(format: "%.2f", distanceInMiles)
    }
    
    private var rateString: String {
        let rateMPH = viewModel.rate * 2.236_94
        return String(format: "%.2f", rateMPH)
    }
    
    // MARK: - View
    
    var body: some View {
        HStack(alignment: .top) {
            distanceView
                .frame(maxWidth: .infinity)
            paceView
                .frame(maxWidth: .infinity)
            timerView
                .frame(maxWidth: .infinity)
        }
        .padding()
    }

    private var distanceView: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: "location.circle")
                .font(.system(size: 24))
                .foregroundColor(.musicMarathonPurple)
            
            VStack(alignment: .leading) {
                Text(distanceString)
                    .font(.system(size: 24, weight: .semibold))
                
                Text("miles")
                    .font(.callout)
            }
        }
    }
    
    private var paceView: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: "speedometer")
                .font(.system(size: 24))
                .foregroundColor(.musicMarathonPurple)
            
            VStack(alignment: .leading) {
                Text(rateString)
                    .font(.system(size: 24, weight: .semibold))
                
                Text("mph")
                    .font(.callout)
            }
        }
    }
    
    private var timerView: some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: "clock")
                .font(.system(size: 24))
                .foregroundColor(.musicMarathonPurple)
            
            HStack(spacing: 2) {
                if hours > 0 {
                    hoursView
                    colonView
                }
                minutesView
                colonView
                secondsView
            }
        }
    }
    
    private var hoursView: some View {
        Text(hours < 10 ? "0" + String(hours) : String(hours))
            .font(.system(size: 24, weight: .semibold))
    }
    
    private var minutesView: some View {
        Text(minutes < 10 ? "0" + String(minutes) : String(minutes))
            .font(.system(size: 24, weight: .semibold))
    }
    
    private var secondsView: some View {
        Text(seconds < 10 ? "0" + String(seconds) : String(seconds))
            .font(.system(size: 24, weight: .semibold))
    }
    
    private var colonView: some View {
        Text(":")
            .font(.system(size: 24, weight: .semibold))
    }
}
