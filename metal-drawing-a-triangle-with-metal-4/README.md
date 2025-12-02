# Drawing a triangle with Metal 4

Render a colorful, rotating 2D triangle by running draw commands with a render pipeline on a GPU.

## Overview

This sample demonstrates how to render imagery by sending commands to the GPU with the Metal 4 API,
and relates to WWDC25 session 205: [Discover Metal 4](https://developer.apple.com/wwdc25/205).

Multiple times a second, the sample's app displays a colorful triangle by:
1. Updating the vertex data for the triangle
2. Encoding draw commands as a *frame* of visual content
3. Running the draw commands on a Metal device that represents an Apple silicon GPU
4. Updating the display after the GPU finishes rendering that frame

Apps can give a person the impression of motion by rendering and displaying frames at a sufficient frequency,
typically at 60 frames or more per second.

The renderer encodes one frame at a time, and has three frames of content in flight at the same time.
Starting when the first frame is visible on the display, the renderer is continually managing three frames at once:

- The first frame is in its final lifetime phase as the frame that's visible to a person on the device's display.
- The second frame is in its second lifetime phase where the GPU renders it in a *render pass*, which is the collection of render commands that draw the triangle.
- The third frame is in its first lifetime phase where the renderer encodes the draw commands for the next render pass by using the Metal API on the CPU.

The renderer manages the frames as each progresses through its three lifetime phases.
The diagram below illustrates how the first frames move through time, where each column represents a snapshot of the app's current frames and their states:

![A timeline diagram that shows how frames progress through their lifetime phases by dividing time into vertical columns, each of which represents a snapshot in time as they flow from left to right. The first column has one box with the label "encode frame 1". The second column has two boxes with the labels "encode frame 2" and "execute frame 1". The third column has three boxes with the labels "encode frame 3", "execute frame 2" and "display frame 1". The next two columns continue the pattern with three boxes each, where column five has the labels "encode frame 5", "execute frame 4", and "display frame 3". The final, right-most column has three boxes, each with an ellipsis that indicates the pattern continues indefinitely.](Documentation/drawing-a-triangle-with-metal-4-1@2x.png)

For more information about the app and how it works, see
[Drawing a triangle with Metal 4](https://developer.apple.com/documentation/metal/drawing-a-triangle-with-metal-4)
in the developer documentation.
