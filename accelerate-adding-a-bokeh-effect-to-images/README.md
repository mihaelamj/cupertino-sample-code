# Adding a bokeh effect to images

Simulate a bokeh effect by applying dilation.

## Overview

This sample app creates a bokeh effect, where parts of an image that are out of focus adopt the shape of the lens's aperture. The app dynamically generates a polygon-shaped kernel — also known as a _structuring element_ — and applies a morphology operation to an image based on that kernel. The following sample shows a photograph after the app has applied dilation with a triangular kernel:

![A photograph showing the results of a bokeh effect. Many small, triangular kernels together form the larger image of a bowl of fruit.](Documentation/triangle_dilation_result_2x.png)

Kernels are 1D or 2D matrices of values that the morphology operation subtracts from a corresponding pixel value in the image. The final value of each transformed pixel is either the lightest result (for dilation) or darkest result (for erosion) of each subtraction.

![A diagram that depicts the dilation of a kernel to create a bokeh effect. In the background, a grid of pixel values represent the original image. An additional grid of pixel values, representing the structuring element, is overlaid on the first grid. In the foreground, another grid shows the new pixel values resulting from the morphology operation.](Documentation/morphology_diagram_2x.png)

The following formula shows how a dilation operation calculates the value for the pixel at the center of the grid. The operation subtracts each of the nine kernel values from the image's corresponding pixel and returns the maximum value.

![A mathematical formula that represents pixel dilation to create a bokeh effect. A matrix of nine values, representing the structuring element, is subtracted from another matrix of nine values, representing a pixel from the original image. The operation returns a maximum value of 3, resulting in dilation.](Documentation/dilation_formula_2x.png)

## Generate the structuring element

The `MorphologyTransformer.makeBokehStructuringElement(ofRadius:atAngle:withSides:)` method returns a `vImage.StructuringElement<Pixel_8>` structure. Within that structure, the `diaphragmBladeCount` variable defines the number of sides. For example, to create a hexagon-shaped bokeh effect, the sample app calls the `MorphologyTransformer.makeBokehStructuringElement(ofRadius:atAngle:withSides:)` method with the number of sides set to `6`.

``` swift
/// The number of edges on the bokeh polygon.
@Published var diaphragmBladeCount = 6.0 {
    didSet {
        Task(priority: .userInitiated) {
            await applyBokeh()
        }
    }
}
```
``` swift
let bokeh = Self.makeBokehStructuringElement(ofRadius: Int(bokehRadius),
                                             atAngle: angle,
                                             withSides: Int(diaphragmBladeCount))
```

On return, `bokeh` contains the following values:

![A diagram depicting the hexagonal dilation kernel from the preceding code sample. In a square grid, cells containing the value 255 surround a cluster of shaded cells containing the value 0, representing the six-sided kernel.](Documentation/bokeh_kernel_2x.png)

## Apply the dilation

To optimize the dilation operations, the sample app calls the planar morphology function, [`applyMorphology(operation:destination:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951577-applymorphology), concurrently on the three planar pixel buffers that represent the individual red, green, and blue channels. 

To learn more about improving your app's performance by converting image buffer formats from interleaved to planar, see [Optimizing image-processing performance](https://developer.apple.com/documentation/accelerate/optimizing-image-processing-performance).

The following code calls the three functions inside a [`withTaskGroup(of:returning:body:)`](https://developer.apple.com/documentation/swift/withtaskgroup(of:returning:body:)) closure:

``` swift
/// Apply dilation to the red channel.
group.addTask(priority: .userInitiated) { [self] in
    sourceRedBuffer.applyMorphology(operation: .dilate(structuringElement: bokeh),
                                    destination: destinationRedBuffer)
}

/// Apply dilation to the green channel.
group.addTask(priority: .userInitiated) { [self] in
    sourceGreenBuffer.applyMorphology(operation: .dilate(structuringElement: bokeh),
                                      destination: destinationGreenBuffer)
}

/// Apply dilation to the blue channel.
group.addTask(priority: .userInitiated) { [self] in
    sourceBlueBuffer.applyMorphology(operation: .dilate(structuringElement: bokeh),
                                     destination: destinationBlueBuffer)
}
```

On return, the destination buffer contains the dilation result:

![A photograph showing the results of pixel dilation from the preceding code sample. Many small, hexagonal kernels together form the larger image of a bowl of fruit.](Documentation/hexagon_dilation_result_2x.png)
