# Processing a texture in a compute function

Copy, modify, and render texture data by running a compute and render pass on the GPU.

This sample demonstrates how to:
- Encode copy commands that run in parallel
- Convert a color image to its grayscale equivalent
- Render textures to the display

At launch, the app creates color textures by importing color image files.
For each frame, the app runs a compute pass and a render pass.

The compute pass:

* Combines the content of two textures into a composite color texture with copy commands that run during a blit stage
* Creates a grayscale version of the composite color texture by converting each pixel
with a compute kernel that runs in a dispatch stage

> Note:
The GPU can run the copy commands at the same time
because the memory ranges they modify in the destination texture don't overlap.  

The render pass draws the composite color and grayscale textures,
and presents the results to the display.

For more information about the app and how it works, see
[Processing a texture with a compute function](https://developer.apple.com/documentation/metal/processing-a-texture-with-a-compute-function)
in the developer documentation.
