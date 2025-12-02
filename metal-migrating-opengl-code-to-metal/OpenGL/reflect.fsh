/*
 <samplecode>
 <abstract>
 Source for the GLSL fragment shader that you use to render the reflective quad.
 </abstract>
 </samplecode>
 */

#ifdef GL_ES
precision highp float;
#endif

// Color of the tint (blue) that you apply to the reflection.
const vec4 tintColor = vec4(0.0, 0.0, 1.0, 1.0);

// Amount of tint to apply.
const float tintFactor = 0.02;

#if __VERSION__ >= 140
in  vec2 varTexcoord;
out vec4 fragColor;
#else
varying vec2 varTexcoord;
#endif

uniform sampler2D baseColorMap;

void main (void)
{
#if __VERSION__ >= 140
    // Do a lookup into the environment map.
    vec4 texColor = texture(baseColorMap, varTexcoord);

    // Add some blue tint to the image so it resembles a mirror or glass.
    fragColor = mix(texColor, tintColor, tintFactor);
#else
    // Do a lookup into the environment map.
    vec4 texColor = texture2D(baseColorMap, varTexcoord);

    // Add some blue tint to the image so it resembles a mirror or glass.
    gl_FragColor = mix(texColor, tintColor, tintFactor);
#endif
}
