/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The map annotation image view.
*/

import SwiftUI

struct AnnotationImage: View {
    let name: String
    
    var body: some View {
        Image(systemName: name)
            .font(.title)
            .foregroundColor(.red)
            .contentShape(Rectangle())
    }
}

#Preview {
    AnnotationImage(name: "car")
    AnnotationImage(name: "mappin.and.ellipse")
}
