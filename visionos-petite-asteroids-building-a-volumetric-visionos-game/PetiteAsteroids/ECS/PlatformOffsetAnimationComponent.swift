/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that tracks the state for platform animations.
*/

import RealityKit

struct PlatformOffsetAnimationComponent: Component {
    
    /// Create shader parameters for each material instance in your scene.
    let platformIndexParameterHandle = ShaderGraphMaterial.parameterHandle(name: "PlatformIndex")
    let offsetYParameterHandle = ShaderGraphMaterial.parameterHandle(name: "OffsetY")
    
    /// The id of the platform to animate.
    var platformIndex: Int = 0
    
    /// The value to animate in a system.
    var offsetY: Float = 0
    
    /// To create an animation that responds to physics, track the animation's `velocity` in this component.
    var velocity: Float = 0
}
