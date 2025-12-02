/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Useful constants that are shared across the app.
*/

import MapKit

extension CLLocationCoordinate2D {

    static let eventCenter = CLLocationCoordinate2D(latitude: 37.332_16, longitude: -121.889_60)
}

extension MKCoordinateRegion {

    // The default map view region in the After Hours view.
    static let afterHours = MKCoordinateRegion(center: CLLocationCoordinate2D.eventCenter,
                                            latitudinalMeters: 500, longitudinalMeters: 500)

    // The region used for search and autocompletion.
    static let search = MKCoordinateRegion(center: CLLocationCoordinate2D.eventCenter,
                                           latitudinalMeters: 2000, longitudinalMeters: 2000)

    // The default map view region in the event view.
    static let event = MKCoordinateRegion(center: CLLocationCoordinate2D.eventCenter,
                                          latitudinalMeters: 200, longitudinalMeters: 200)

    // The region that defines the camera boundary used in the event view.
    static let cameraBoundary = MKCoordinateRegion(center: CLLocationCoordinate2D.eventCenter,
                                                   latitudinalMeters: 100, longitudinalMeters: 80)
}
