/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The detail view of the watch app, showing the variant list of each complication family.
*/

import SwiftUI

// Changing the "selection" binding doesn't trigger the UI update when this sample is written.
// To work around the issue, put @EnvironmentObject here so that changing "selection" triggers
// the UI update.
//
struct VariantListView: View {
    @EnvironmentObject var configuration: TemplateConfiguration
    let variantList: [String]
    @Binding var selection: String

    var body: some View {
        List(variantList, id: \.self) { variant in
            HStack {
                if variant == self.selection {
                    Image(systemName: "star.fill")
                        .imageScale(.medium)
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "star")
                        .imageScale(.medium)
                        .foregroundColor(.gray)
                }
                Text(variant)
                    .font(.body)
                    .padding(4)
            }
            .onTapGesture { self.selection = variant }
        }
    }
}

struct VariantListView_Previews: PreviewProvider {
    static var previews: some View {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        return VariantListView(variantList: GraphicCircularVariant.allRawValues,
                               selection: .constant(delegate.templateConfiguration.graphicCircular))
    }
}
