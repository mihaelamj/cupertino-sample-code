/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`MapScrollView` is a `UIScrollView` that displays a single static map image while still allowing for panning and zooming.
*/

import Foundation
import UIKit

/**
 The Coastal Roads map displays as a static image inside a UIScrollView, which enables panning and zooming.
 It supports only a single hardcoded route for navigation, and when the app is in navigation mode,
 the camera viewport animates between several predefined points on the map.
 In a real navigation app that uses a map with tiles, these locations would appear at runtime
 in latitude/longitude format.
 */
enum CRZoomLocation {
    case routeOverview, routeDestination, routeOrigin, routeTurn1, routeTurn2, routeTurn3

    var frame: CGRect {
        switch self {
        case .routeOverview:
            return CGRect(x: 0, y: 0, width: 3072, height: 2048)
        case .routeOrigin:
            return CGRect(x: 650, y: 600, width: 800, height: 480)
        case .routeTurn1:
            return CGRect(x: 700, y: 600, width: 800, height: 480)
        case .routeTurn2:
            return CGRect(x: 700, y: 750, width: 800, height: 480)
        case .routeTurn3:
            return CGRect(x: 1100, y: 750, width: 800, height: 480)
        case .routeDestination:
            return CGRect(x: 1100, y: 650, width: 800, height: 480)
        }
    }
}

class MapScrollView: UIScrollView, UIScrollViewDelegate {
    public let imageView: UIImageView

    init(frame: CGRect, image: UIImage) {
        imageView = UIImageView(image: image)
         
        super.init(frame: frame)

        addSubview(imageView)
        imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)

        contentSize = image.size
        scrollsToTop = false

        isScrollEnabled = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bounces = false
        bouncesZoom = false

        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    final func canZoomIn() -> Bool {
        return zoomScale < maximumZoomScale
    }

    final func zoomIn() {
        setZoomScale(zoomScale * 1.5, animated: true)
    }

    final func canZoomOut() -> Bool {
        return zoomScale > minimumZoomScale
    }

    final func zoomOut() {
        setZoomScale(zoomScale * 0.67, animated: true)
    }

    final func zoomToLocation(_ location: CRZoomLocation) {
        zoom(to: location.frame, animated: true)
    }

    // MARK: UIScrollViewDelegate

    final func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
