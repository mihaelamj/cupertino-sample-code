# Performing Calculations on a GPU

Use Metal to find GPUs and perform calculations on them.

## Overview

In this sample, you’ll learn essential tasks that are used in all Metal apps.
You'll see how to convert a simple function written in C to
Metal Shading Language (MSL) so that it can be run on a GPU.
You'll find a GPU, prepare the MSL function to run on it by creating a pipeline,
and create data objects accessible to the GPU.
To execute the pipeline against your data, create a *command buffer*,
write commands into it, and commit the buffer to a command queue.
Metal sends the commands to the GPU to be executed.

For more information about the sample app and how it works, see
[Performing calculations on a GPU](https://developer.apple.com/documentation/metal/performing-calculations-on-a-gpu)
in the developer documentation.
