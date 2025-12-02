/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The annotation views that represent the different types of cycles.
*/
import MapKit

private let multiWheelCycleClusterID = "multiWheelCycle"

/// - Tag: UnicycleAnnotationView
class UnicycleAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "unicycleAnnotation"

    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "unicycle"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultLow
        markerTintColor = UIColor.unicycleColor
        glyphImage = #imageLiteral(resourceName: "unicycle")
    }
}

/// - Tag: BicycleAnnotationView
class BicycleAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "bicycleAnnotation"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = multiWheelCycleClusterID
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// - Tag: DisplayConfiguration
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.bicycleColor
        glyphImage = #imageLiteral(resourceName: "bicycle")
    }
}

class TricycleAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "tricycleAnnotation"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = multiWheelCycleClusterID
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.tricycleColor
        glyphImage = #imageLiteral(resourceName: "tricycle")
    }
}
