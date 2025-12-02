/*
 <samplecode>
 <abstract>
 Source for the GLSL vertex shader that you use to render the reflective quad.
 </abstract>
 </samplecode>
 */

#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 140
in  vec4 inPosition;
in  vec2 inTexcoord;
out vec2 varTexcoord;
#else
attribute vec4 inPosition;
attribute vec2 inTexcoord;
varying   vec2 varTexcoord;
#endif

// Declare the model-view-projection matrix that you calculate outside the shader
// set for each frame.
uniform mat4 modelViewProjectionMatrix;

void main (void)
{
    gl_Position = modelViewProjectionMatrix * inPosition;
    varTexcoord = inTexcoord;
}
