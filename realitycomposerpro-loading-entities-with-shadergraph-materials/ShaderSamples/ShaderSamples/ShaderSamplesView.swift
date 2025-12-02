/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that loads and displays a collection of shader samples in a scroll view.
*/

import RealityKit
import RealityKitContent
import SwiftUI

struct ShaderSamplesView: View {
    // The shader sample display entities.
    @State var shaderSampleEntities: [Entity] = []

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(shaderSampleEntities) { shaderSampleEntity in
                    VStack {
                        // Display the shader sample entity.
                        createRealityView(shaderSampleEntity)

                        // Display the shader name.
                        createDisplayName(shaderSampleEntity)
                    }.padding([.bottom])
                }
            }
        }.task {
            // Load the shader samples scene root.
            await loadShaders()
        }
    }

    private func createRealityView(_ shaderSampleEntity: Entity) -> some View {
        RealityView { content in
            shaderSampleEntity.position = [0, 0, 0]
            shaderSampleEntity.scale = SIMD3<Float>(
                repeating: 0.75)
            content.add(shaderSampleEntity)
        }
        .glassBackgroundEffect()
        .containerRelativeFrame(
            [.horizontal], count: 3, spacing: 5)
    }

    private func createDisplayName(_ shaderSampleEntity: Entity) -> some View {

        let shaderName = shaderSampleEntity.name.replacingOccurrences(
            of: "Shader", with: "")

        return Text(shaderName)
            .padding()
            .glassBackgroundEffect()
    }

    private func loadShaders() async {
        guard
            let shaderSamplesSceneRoot = try? await Entity(
                named: "ShaderSamplesScene", in: realityKitContentBundle
            ).children.first
        else {
            return
        }

        // Get the shader sample entities.
        for shaderSampleEntity in shaderSamplesSceneRoot.children {
            shaderSampleEntities.append(shaderSampleEntity)
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ShaderSamplesView()
}
