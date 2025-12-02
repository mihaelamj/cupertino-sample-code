# Adjusting the level of detail using Metal mesh shaders

Choose and render meshes with several levels of detail using object and mesh shaders.

## Overview

- Note: This sample code project is associated with WWDC22 session [10162: Transform your geometry with Metal mesh shaders](https://developer.apple.com/wwdc22/10162/).

## Configure the sample code project

To run this sample, you need Xcode 14 or later, and a physical device that supports [`MTLGPUFamilyMac2`](https://developer.apple.com/documentation/metal/mtlgpufamily/mac2) or [`MTLGPUFamilyApple7`](https://developer.apple.com/documentation/metal/mtlgpufamily/apple7), such as:

* A Mac running macOS 13 or later
* An iOS device with an A15 chip or later running iOS 16 or later

This sample can only run on a physical device because it uses Metal's mesh shader features, which Simulator doesn't support.
