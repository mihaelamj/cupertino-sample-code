/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`TemplateManager+Location` manages the CLLocationManagerDelegate in the app.
*/

import CoreLocation
import CarPlay

extension TemplateManager: CLLocationManagerDelegate {
    
    /// - Tag: location
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied, .restricted, .notDetermined:
            let alert = CPAlertTemplate(
                titleVariants: ["Please enable location services."],
                actions: [
                    CPAlertAction(
                        title: "Ok",
                        style: .default,
                        handler: { [weak self] (action) in
                            self?.carplayInterfaceController?.setRootTemplate(
                                CPTabBarTemplate(templates: []), animated: false, completion: { (done, error) in
                                    MemoryLogger.shared.appendEvent("Error setting root template.")
                                }
                            )
                        }
                    )
                ])
            
            // Check for a presented template and dismiss it for this important message.
            if carplayInterfaceController?.presentedTemplate != nil {
                dismissAlertAndPopToRootTemplate {
                    self.carplayInterfaceController?.presentTemplate(alert, animated: false, completion: { [weak self] (done, error) in
                        self?.handleError(error, prependedMessage: "Error presenting \(alert.classForCoder)")
                    })
                }
            } else {
                carplayInterfaceController?.presentTemplate(alert, animated: false, completion: { [weak self] (done, error) in
                    self?.handleError(error, prependedMessage: "Error presenting \(alert.classForCoder)")
                })
            }
        default:
            dismissAlertAndPopToRootTemplate {
                self.setupMap()
            }
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        boundingRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 12_000, longitudinalMeters: 12_000)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MemoryLogger.shared.appendEvent("Location Error: \(error.localizedDescription).")
    }
}
