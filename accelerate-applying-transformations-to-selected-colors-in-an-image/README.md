# Applying transformations to selected colors in an image

Desaturate a range of colors in an image with a multidimensional lookup table. 

## Overview

This sample code app allows you to desaturate the colors in an image based on their similarity to a selected color. For example, the image below shows an original image (left) and the transformed image (right) where the app has transformed the cake sprinkles that aren't yellow to grayscale.

![A comparison of the original image of colorful cake sprinkles with its selectively-desaturated counterpart.](Documentation/comparison_2x.png)

Before exploring the code, try building and running the app to familiarize yourself with the effect of the different transformations on the image. In the app, click the smaller image to select a color and the app displays the transformed result as the larger image. 

## Create the lookup table data

The multidimensional lookup table that this sample code project uses is a 3D cube with `entriesPerChannel` values along each axis.

The app defines the `targetLabColor` variable as the color that the user selects in the user interface.

``` swift
let targetLabColor = ColorConverter.rgbToLab(red: targetRGB[0],
                                             green: targetRGB.count > 1 ? targetRGB[1] : targetRGB[0],
                                             blue: targetRGB.count > 2 ? targetRGB[2] : targetRGB[0])
```

The code below performs `entriesPerChannel` iterations from `0` to `1` over each color channel to populate the multidimensional lookup table data. With each iteration, the code calls [`simd_distance`](https://developer.apple.com/documentation/accelerate/2896521-simd_distance) to compute the Euclidean distance in L\*a\*b\* color space between the target color and the color that red, green, and blue loops define.

The distance between the two colors forms the basis for the amount of desaturation or darkening that the app applies to each color value in the lookup table. 

``` swift
var bufferIndex = 0
let multiplier = CGFloat(UInt16.max)
for red in ramp {
    for green in ramp {
        for blue in ramp {
           
            let srcLabColor = ColorConverter.rgbToLab(red: red, green: green, blue: blue)
            
            let distance = simd_distance(targetLabColor, srcLabColor)
            
            let effectMultiplier = 1 - simd_smoothstep(0, tolerance, distance)
            
            let src = NSColor(red: red,
                              green: green,
                              blue: blue,
                              alpha: 1)
            
            let dest = NSColor(hue: src.hueComponent,
                               saturation: src.saturationComponent * (desaturate ? CGFloat(effectMultiplier) : 1),
                               brightness: src.brightnessComponent * (darken ? CGFloat(effectMultiplier) : 1),
                               alpha: 1)
            
            lookupTableData[ bufferIndex ] = UInt16(dest.redComponent * multiplier)
            bufferIndex += 1
            
            lookupTableData[ bufferIndex ] = UInt16(dest.greenComponent * multiplier)
            bufferIndex += 1
            
            lookupTableData[ bufferIndex ] = UInt16(dest.blueComponent * multiplier)
            bufferIndex += 1
        }
    }
}
```

For more information about creating multidimensional lookup table data, see [Applying color transforms to images with a multidimensional lookup table](https://developer.apple.com/documentation/accelerate/applying_color_transforms_to_images_with_a_multidimensional_lookup_table).

## Create the multidimensional lookup

The [`vImage.MultidimensionalLookupTable`](https://developer.apple.com/documentation/accelerate/vimage/multidimensionallookuptable) structure uses the lookup table to transform the source image, either desaturating or darkening colors that aren't close to the selected target color.

The code below creates a multidimension lookup table structure, applies the lookup table to the three source planar buffers, and writes the result to the three destination buffers: 

``` swift
let lookupTable = vImage.MultidimensionalLookupTable(
    entryCountPerSourceChannel: entryCountPerSourceChannel,
    destinationChannelCount: destChannelCount,
    data: lookupTableData)

lookupTable.apply(sources: rgbSourceBuffers,
                  destinations: [ redDestinationBuffer,
                                  greenDestinationBuffer,
                                  blueDestinationBuffer ],
                  interpolation: .full)
```

The three destination planar buffers contain the transformed image.

## Create a Core Graphics image

The code below interleaves the three planar buffers into a single RGB buffer. Finally, the [`makeCGImage(cgImageFormat:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951698-makecgimage) function returns a Core Graphics image that the app displays in the user interface.

``` swift
interleavedDestinationBuffer.interleave(planarSourceBuffers: [ redDestinationBuffer,
                                                               greenDestinationBuffer,
                                                               blueDestinationBuffer ])
```
