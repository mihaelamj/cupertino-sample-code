/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI map view subclass.
*/

import CoreLocation
import MapKit
import SwiftUI

/// The map the app displays during a workout.
struct MapView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: WorkoutViewModel
    
    // MARK: - View
    
    var body: some View {
        Map(coordinateRegion: $viewModel.currentLocation, showsUserLocation: true)
            .onAppear {
                viewModel.verifyLocationServicesEnabled()
            }
            .ignoresSafeArea()
    }
}
