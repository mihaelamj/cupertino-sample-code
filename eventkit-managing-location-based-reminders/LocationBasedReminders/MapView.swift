/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The map view.
*/

import MapKit
import SwiftUI

struct MapView: View {
    @State private var locationManager = LocationManager()
    @State private var mapData = MapAnnotationData()
    @State private var position: MapCameraPosition = .region(.sanFrancisco)
    @State private var selection: MapSelection<Int>?
    
    /// The app displays the map user location button when the person authorizes access to location services.
    private var isAuthorizationGranted: Bool {
        guard let status = locationManager.authorizationStatus else { return false }
        return status == .authorizedWhenInUse
    }
    
   /*
      The app displays a settings button that prompts for permission to use
      location services when a person taps it. The app shows the button when it
      can't determine its authorization status. The app hides it, otherwise.
    */
    private var isAuthorizationUnknown: Bool {
        let status = locationManager.authorizationStatus
        
        if status == nil {
            return true
        } else if let status, status == .notDetermined {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            Map(position: $position, selection: $selection) {
                UserAnnotation { userAnnotation in
                    if let location = userAnnotation.location {
                        NavigationLink {
                            NewReminderEditor(location: location)
                        } label: {
                            AnnotationImage(name: "car")
                        }
                    }
                }
                .tag(MapSelection(1))
                    
                ForEach(mapData.annotations) { annotation in
                    Annotation(annotation.name, coordinate: annotation.location.coordinate, anchor: .bottom) {
                        NavigationLink {
                            NewReminderEditor(annotation: annotation)
                        } label: {
                            AnnotationImage(name: "mappin.and.ellipse")
                        }
                    }
                    .tag(MapSelection(annotation.id))
                }
            }
            .mapControls {
                if isAuthorizationGranted {
                    MapUserLocationButton()
                }
            }
            .toolbar {
                if isAuthorizationUnknown {
                    settingButton
                }
            }
        }
    }
    
    private var settingButton: some View {
        Button {
            locationManager.requestAuthorization()
        } label: {
            Label("Settings", systemImage: "gear")
        }
    }
}

#Preview {
    MapView()
}
