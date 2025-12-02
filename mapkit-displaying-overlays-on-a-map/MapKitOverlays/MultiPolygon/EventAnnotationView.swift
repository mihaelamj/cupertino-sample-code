/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom annotation view that displays text.
*/

import MapKit

class EventAnnotationView: MKAnnotationView {

    private let label: UILabel

    override var annotation: MKAnnotation? {
        didSet {
            /*
             The map view reuses annotation views to represent different annotations. Always update the label title to
             ensure it represents the current annotation.
            */
            if let title = annotation?.title {
                label.text = title
            } else {
                label.text = nil
            }
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        label = UILabel(frame: .zero)
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        isEnabled = false
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
