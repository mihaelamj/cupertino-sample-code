/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model describing one item in the introduction view.
*/

struct DescriptionPoint: Identifiable {

    let icon: String
    let headline: String
    let body: String
    
    var id: String { icon }
}

