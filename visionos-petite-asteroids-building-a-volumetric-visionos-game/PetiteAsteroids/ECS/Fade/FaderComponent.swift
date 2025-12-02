/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the state for the fader system.
*/

import RealityKit

struct FaderComponent: Component {
    var materialIndices: Set<Int>? = nil
    var isFading = false
    var timingFunction: EasingFunction = .easeInOutQuad
    var fadeType: FadeType = .fadeOut
    var fadeDuration: Float = 1
    var fadeTime: Float = 0
    var fadeMixAmount: Float = 0
    let fadeMixAmountParameterHandle = ShaderGraphMaterial.parameterHandle(name: "FadeMixAmount")
    let fadeColorBottomParameterHandle = ShaderGraphMaterial.parameterHandle(name: "FadeColorBottom")
    let fadeColorTopParameterHandle = ShaderGraphMaterial.parameterHandle(name: "FadeColorTop")
    let gradientGammaParameterHandle = ShaderGraphMaterial.parameterHandle(name: "GradientGamma")
    let gradientStartYParameterHandle = ShaderGraphMaterial.parameterHandle(name: "GradientStartY")
    let gradientEndYParameterHandle = ShaderGraphMaterial.parameterHandle(name: "GradientEndY")
}

enum FadeType {
    case fadeIn
    case fadeOut
}
