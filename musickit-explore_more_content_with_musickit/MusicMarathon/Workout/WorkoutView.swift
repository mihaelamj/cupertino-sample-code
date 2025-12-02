/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays workout information.
*/

import MapKit
import MusicKit
import SwiftUI

/// The main view the app displays during a workout. It shows the map, various metrics, and the mini music player.
struct WorkoutView: View {
    
    // MARK: - Properties
    
    @StateObject var viewModel = WorkoutViewModel()
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            MapView(viewModel: viewModel)
            workoutDetailsView
        }
        .navigationBarBackButtonHidden()
    }
    
    private var workoutDetailsView: some View {
        VStack {
            WorkoutDataView(viewModel: viewModel)
                .background {
                    RoundedRectangle(cornerRadius: Self.backgroundCornerRadius, style: .continuous)
                        .fill(Color(UIColor.systemBackground))
                        .padding([.leading, .trailing])
                        .standardShadow()
                }
            Spacer()
            miniPlayer
            Button(action: end) {
                Text("End Workout")
                    .frame(minWidth: Self.endButtonMinWidth)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.workout)
            .standardShadow()
        }
    }
    
    @ViewBuilder
    private var miniPlayer: some View {
        MiniPlayer()
    }
    
    // MARK: - Methods
    
    private func end() {
        viewModel.endWorkout()
        ApplicationMusicPlayer.shared.stop()
        self.presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Constants
    
    private static let backgroundCornerRadius: CGFloat = 25
    private static let endButtonMinWidth: CGFloat = 180
}
