/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper struct to associate map overlays with ARGeoAnchors.
*/

import ARKit

struct GeoAnchorWithAssociatedData {
    let geoAnchor: ARGeoAnchor
    let mapOverlay: AnchorIndicator
}
