/*
 <samplecode>
 <abstract>
 Source for the GLSL vertex shader that you use to render the temple model.
 </abstract>
 </samplecode>
 */

#ifdef GL_ES
precision highp float;
#endif

/* Declare inputs and outputs.
 * `inPosition`     : Position attributes from the VAOs and VBOs.
 * `inTexcoord`     : Texture coordinate attributes from the VAOs and VBOs.
 * `varTexcoord`    : Texture coordinates that you pass to the rasterizer.
 * `gl_Position`    : Implicitly declared in all vertex shaders. Clip space position
                      that you pass to the rasterizer and use to build the triangles.
 */

#if __VERSION__ >= 140
in  vec4 inPosition;
in  vec2 inTexcoord;
in  vec3 inNormal;
out vec2 varTexcoord;
out vec3 varColor;
#else
attribute vec4 inPosition;
attribute vec2 inTexcoord;
attribute vec3 inNormal;
varying   vec2 varTexcoord;
varying   vec3 varColor;
#endif

uniform mat4 modelViewProjectionMatrix;

// Per-mesh uniforms.
uniform mat3 templeNormalMatrix;

// Per-light properties.
uniform vec3 ambientLightColor;
uniform vec3 directionalLightInvDirection;
uniform vec3 directionalLightColor;

void main (void)
{
    // Calculate the position of the vertex in clip space and output the value for clipping
    // and rasterization.
    gl_Position = modelViewProjectionMatrix * inPosition;

    // Pass along the texture coordinate of the vertex for the fragment shader to use to
    // sample from the texture.
    varTexcoord = inTexcoord;

    // Rotate the normal to model space.
    vec3 normal = templeNormalMatrix * inNormal;

    // Light falls off based on how closely aligned the surface normal is to the light direction.
    float nDotL = clamp(dot(normal, directionalLightInvDirection), 0.0, 1.0);

    // The diffuse term is the product of the light color, the surface material reflectance,
    // and the falloff.
    vec3 diffuseTerm = directionalLightColor * nDotL;

    // Calculate the diffuse contribution from this light.
    vec3 directionalContribution = (diffuseTerm + ambientLightColor);

    varColor = directionalContribution;
}
