/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose customizable options on the reconstructed model and textures and process multiple detail levels.
*/

import SwiftUI
import RealityKit

struct AdvancedReconstructionOptions: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    var body: some View {
        @Bindable var appDataModel = appDataModel

        VStack(alignment: .leading) {
            Text("Advanced Reconstruction Options")
            Divider()
            Form {
                PolygonCountView()
                
                TextureMapsView()
                
                TextureFormatView()
                
                TextureResolutionView()
                
                Divider()
                
                LabeledContent("Processing") {
                    Toggle("Process multiple detail levels", isOn: $appDataModel.detailLevelOptionsUnderAdvancedMenu.isSelected)
                }
                
                Menu("Choose detail levels") {
                    Toggle("Preview", isOn: $appDataModel.detailLevelOptionsUnderAdvancedMenu.preview)

                    Toggle("Reduced", isOn: $appDataModel.detailLevelOptionsUnderAdvancedMenu.reduced)

                    Toggle("Medium", isOn: $appDataModel.detailLevelOptionsUnderAdvancedMenu.medium)

                    Toggle("Full", isOn: $appDataModel.detailLevelOptionsUnderAdvancedMenu.full)

                    Toggle("Raw", isOn: $appDataModel.detailLevelOptionsUnderAdvancedMenu.raw)

                }
                .disabled(!appDataModel.detailLevelOptionsUnderAdvancedMenu.isSelected)
            }
        }
        .padding()
    }
}
