/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component marking an entity that can receive drop shadows, and contains state data the drop-shadow system uses.
*/

import RealityKit

struct DropShadowReceiverModelComponent: Component {
    // Create shader parameters for each material instance in your scene.
    let worldToLevelMatrixParameterHandle = ShaderGraphMaterial.parameterHandle(name: "WorldToLevelMatrix")
    var shadowMaterialIndices = Set<Int>()
}
