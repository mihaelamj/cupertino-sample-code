/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Components that mark entities as being baked shadow receivers.
*/

import RealityKit

struct UniqueBakedShadowReceiverComponent: Component {
    let receivesShadowsParameterHandle = ShaderGraphMaterial.parameterHandle(name: "ReceivesShadows")
    let worldToShadowMatrixParameterHandle = ShaderGraphMaterial.parameterHandle(name: "WorldToShadowMatrix")
}
struct SharedBakedShadowReceiverComponent: Component {
    let receivesShadowsParameterHandle = ShaderGraphMaterial.parameterHandle(name: "ReceivesShadows")
    let worldToShadowMatrixParameterHandle = ShaderGraphMaterial.parameterHandle(name: "WorldToShadowMatrix")
}
