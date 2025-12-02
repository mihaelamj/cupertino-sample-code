/*
 <samplecode>
 <abstract>
 Source for the GLSL fragment shader that you use to render the temple model.
 </abstract>
 </samplecode>
 */

#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in  vec2 varTexcoord;
in  vec3 varColor;
out vec4 fragColor;
#else
varying vec2 varTexcoord;
varying vec3 varColor;
#endif

uniform sampler2D baseColorMap;

void main (void)
{
#if __VERSION__ >= 140
    vec4 baseColorSample = texture(baseColorMap, varTexcoord.st);
    fragColor.xyz = varColor * baseColorSample.xyz;
    fragColor.w = baseColorSample.w;
#else
    vec4 baseColorSample = texture2D(baseColorMap, varTexcoord.st);
    gl_FragColor.xyz = varColor * baseColorSample.xyz;
    gl_FragColor.w = baseColorSample.w;
#endif
}
