/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller containing the `MKMapView`, as well as adding and removing `MKMarkerAnnotationView` through its toolbar.
*/

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
    
    private var allAnnotations: [MKAnnotation]?
    
    private var displayedAnnotations: [MKAnnotation]? {
        willSet {
            if let currentAnnotations = displayedAnnotations {
                mapView.removeAnnotations(currentAnnotations)
            }
        }
        didSet {
            if let newAnnotations = displayedAnnotations {
                mapView.addAnnotations(newAnnotations)
            }
            centerMapOnSanFrancisco()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerMapAnnotationViews()
        
        let flowerAnnotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: 37.772_623, longitude: -122.460_217))
        flowerAnnotation.title = NSLocalizedString("FLOWERS_TITLE", comment: "Flower annotation")
        flowerAnnotation.imageName = "conservatory_of_flowers"
        
        // Create the array of annotations and the specific annotations for the points of interest.
        allAnnotations = [SanFranciscoAnnotation(), BridgeAnnotation(), FerryBuildingAnnotation(), flowerAnnotation]
        
        // Dispaly all annotations on the map.
        showAllAnnotations(self)
    }
    
    /// Register the annotation views with the `mapView` so the system can create and efficently reuse the annotation views.
    /// - Tag: RegisterAnnotationViews
    private func registerMapAnnotationViews() {
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(BridgeAnnotation.self))
        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(CustomAnnotation.self))
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(SanFranciscoAnnotation.self))
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(FerryBuildingAnnotation.self))
    }
    
    private func centerMapOnSanFrancisco() {
        let span = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        let center = CLLocationCoordinate2D(latitude: 37.786_996, longitude: -122.440_100)
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }
    
    // MARK: - Button Actions
    
    private func displayOne(_ annotationType: AnyClass) {
        let annotation = allAnnotations?.first { (annotation) -> Bool in
            return annotation.isKind(of: annotationType)
        }
        
        if let oneAnnotation = annotation {
            displayedAnnotations = [oneAnnotation]
        } else {
            displayedAnnotations = []
        }
    }

    @IBAction private func showOnlySanFranciscoAnnotation(_ sender: Any) {
        // User tapped "City" button in the bottom toolbar
        displayOne(SanFranciscoAnnotation.self)
    }
    
    @IBAction private func showOnlyBridgeAnnotation(_ sender: Any) {
        // User tapped "Bridge" button in the bottom toolbar
        displayOne(BridgeAnnotation.self)
    }
    
    @IBAction private func showOnlyFlowerAnnotation(_ sender: Any) {
        // User tapped "Flower" button in the bottom toolbar
        displayOne(CustomAnnotation.self)
    }
    
    @IBAction private func showOnlyFerryBuildingAnnotation(_ sender: Any) {
        // User tapped "Ferry" button in the bottom toolbar
        displayOne(FerryBuildingAnnotation.self)
    }
    
    @IBAction private func showAllAnnotations(_ sender: Any) {
        // User tapped "All" button in the bottom toolbar
        displayedAnnotations = allAnnotations
    }
}

extension MapViewController: MKMapViewDelegate {

    /// Called whent he user taps the disclosure button in the bridge callout.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // This illustrates how to detect which annotation type was tapped on for its callout.
        if let annotation = view.annotation, annotation.isKind(of: BridgeAnnotation.self) {
            print("Tapped Golden Gate Bridge annotation accessory view")
            
            if let detailNavController = storyboard?.instantiateViewController(withIdentifier: "DetailNavController") {
                detailNavController.modalPresentationStyle = .popover
                let presentationController = detailNavController.popoverPresentationController
                presentationController?.permittedArrowDirections = .any
                
                // Anchor the popover to the button that triggered the popover.
                presentationController?.sourceRect = control.frame
                presentationController?.sourceView = control
                
                present(detailNavController, animated: true, completion: nil)
            }
        }
    }
    
    /// The map view asks `mapView(_:viewFor:)` for an appropiate annotation view for a specific annotation.
    /// - Tag: CreateAnnotationViews
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if let annotation = annotation as? BridgeAnnotation {
            annotationView = setupBridgeAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? CustomAnnotation {
            annotationView = setupCustomAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? SanFranciscoAnnotation {
            annotationView = setupSanFranciscoAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? FerryBuildingAnnotation {
            annotationView = setupFerryBuildingAnnotationView(for: annotation, on: mapView)
        }
        
        return annotationView
    }
    
    /// The map view asks `mapView(_:viewFor:)` for an appropiate annotation view for a specific annotation. The annotation
    /// should be configured as needed before returning it to the system for display.
    /// - Tag: ConfigureAnnotationViews
    private func setupSanFranciscoAnnotationView(for annotation: SanFranciscoAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let reuseIdentifier = NSStringFromClass(SanFranciscoAnnotation.self)
        let flagAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation)
        
        flagAnnotationView.canShowCallout = true
        
        // Provide the annotation view's image.
        let image = #imageLiteral(resourceName: "flag")
        flagAnnotationView.image = image
        
        // Provide the left image icon for the annotation.
        flagAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))
        
        // Offset the flag annotation so that the flag pole rests on the map coordinate.
        let offset = CGPoint(x: image.size.width / 2, y: -(image.size.height / 2) )
        flagAnnotationView.centerOffset = offset
        
        return flagAnnotationView
    }
    
    /// Create an annotation view for the Golden Gate Bridge, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupBridgeAnnotationView(for annotation: BridgeAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(BridgeAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true
            markerAnnotationView.markerTintColor = UIColor(named: "internationalOrange")
            
            /*
             Add a detail disclosure button to the callout, which will open a new view controller or a popover.
             When the detail disclosure button is tapped, use mapView(_:annotationView:calloutAccessoryControlTapped:)
             to determine which annotation was tapped.
             If you need to handle additional UIControl events, such as `.touchUpOutside`, you can call
             `addTarget(_:action:for:)` on the button to add those events.
             */
            let rightButton = UIButton(type: .detailDisclosure)
            markerAnnotationView.rightCalloutAccessoryView = rightButton
        }
        
        return view
    }
    
    private func setupCustomAnnotationView(for annotation: CustomAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        return mapView.dequeueReusableAnnotationView(withIdentifier: NSStringFromClass(CustomAnnotation.self), for: annotation)
    }
    
    /// Create an annotation view for the Ferry Building, and add an image to the callout.
    /// - Tag: CalloutImage
    private func setupFerryBuildingAnnotationView(for annotation: FerryBuildingAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(FerryBuildingAnnotation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true
            markerAnnotationView.markerTintColor = UIColor.purple
            
            // Provide an image view to use as the accessory view's detail view.
            markerAnnotationView.detailCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "ferry_building"))
        }
        
        return view
    }
}
