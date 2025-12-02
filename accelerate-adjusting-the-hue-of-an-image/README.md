# Adjusting the hue of an image

Convert an image to L\*a\*b\* color space and apply hue adjustment. 

## Overview

This sample code project allows you to adjust the hue of an image by treating the chrominance information as 2D coordinates, and transforming those values with a rotation matrix. You can convert an RGB image — with its pixels represented as red, green, and blue values — to L\*a\*b\*, where luminance and chrominance are stored discretely. The _L\*_ in L\*a\*b\* refers to the lightness, and the _a\*_ and _b\*_ refer to the red-green and blue-yellow values, respectively.

The image below shows an approximation of an L\*a\*b\* color chart. The _a\*_ value transitions horizontally (left to right) from negative, through zero, to positive, and the _b\*_ value transitions vertically (bottom to top) from negative, through zero, to positive. Because this sample code focuses on color rather than lightness, the image doesn't consider L\*.

![A graphic containing vertical and horizontal gradients. The gradient colors transition from green on the left to red on the right, and from yellow at the top to blue at the bottom.](Documentation/lab-color-chart_2x.png)

The sample uses the vImage Any-to-Any converter to convert the source image's color space to L\*a\*b\*. The code converts the interleaved L\*a\*b\* image data to multiple-plane image data that it passes to a matrix multiply operation to apply the hue adjustment.

The following image shows four photographs, from left to right, with a hue adjustment of -90º, 0º (an unchanged hue), 90º, and 180º:

![Four photographs of a flower with different hue adjustments.](Documentation/hueAdjust_2x.png)

## Create the L\*a\*b\* image format

To create the image format for the L\*a\*b\* color space, the sample app uses the [`genericLab`](https://developer.apple.com/documentation/coregraphics/cgcolorspace/2923325-genericlab) system-defined [`CGColorSpace`](https://developer.apple.com/documentation/coregraphics/cgcolorspace).

``` swift
var labImageFormat = vImage_CGImageFormat(
    bitsPerComponent: 8,
    bitsPerPixel: 8 * 3,
    colorSpace: CGColorSpace(name: CGColorSpace.genericLab)!,
    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
    renderingIntent: .defaultIntent)!
```

On return, `labImageFormat` describes the interleaved L\*a\*b\* pixels over which this sample works. The first channel in each pixel is the lightness, and the second and third channels are the _a\*_ and _b\*_, respectively.

## Generate the pixel buffer and image format from the source image

The converter that the sample uses to convert the source pixels to L\*a\*b\* color space requires two [`vImage_CGImageFormat`](https://developer.apple.com/documentation/accelerate/vimage_cgimageformat) structures that describe the source and destination images. The sample uses the [`makeDynamicPixelBufferAndCGImageFormat(cgImage:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951699-makedynamicpixelbufferandcgimage) method to create a dynamic pixel buffer and image format structure from the source Core Graphics image.

``` swift
let source = try vImage.PixelBuffer
    .makeDynamicPixelBufferAndCGImageFormat(cgImage: sourceCGImage)
```

On return, `source.cgImageFormat` contains the image format of the source image, and `source.pixelBuffer` is a pixel buffer that contains the source image data.

## Create the source image color space to L\*a\*b\* converter

The sample app uses the source and L\*a\*b\* image formats to create a [`vImageConverter`](https://developer.apple.com/documentation/accelerate/vimageconverter) instance to convert between the two color spaces.

``` swift
let rgbToLab = try vImageConverter.make(sourceFormat: source.cgImageFormat,
                                        destinationFormat: labImageFormat)
```

For more information about vImage's convert-any-to-any functionality, see [Building a Basic Conversion Workflow](https://developer.apple.com/documentation/accelerate/building_a_basic_conversion_workflow).

## Convert the source image to L\*a\*b\*

The sample creates a pixel buffer that's the same size as the source image.

``` swift
labInterleavedSource = vImage.PixelBuffer<vImage.Interleaved8x3>(size: size)
```

The converter's [`convert(from:to:)`](https://developer.apple.com/documentation/accelerate/vimageconverter/3951904-convert) function performs the conversion.

``` swift
try rgbToLab.convert(from: source.pixelBuffer,
                     to: labInterleavedSource)
```

On return, the `labInterleavedSource` contains the L\*a\*b\* representation of the source image. 

## Convert the interleaved L\*a\*b\* buffer to planar buffers

The function the sample app uses to apply the hue adjustment, [`multiply(by:divisor:preBias:postBias:destination:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951701-multiply), operates on a multiple-plane pixel buffer. To convert the interleaved L\*a\*b\* buffer to planar buffers, the app creates a [`Planar8x3`](https://developer.apple.com/documentation/accelerate/vimage/planar8x3) pixel buffer.

``` swift
labPlanarDestination = vImage.PixelBuffer<vImage.Planar8x3>(size: size)
```

It then calls [`deinterleave(destination:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/4018425-deinterleave) to populate the planar buffers with the contents of the interleaved buffer.

``` swift
labInterleavedSource.deinterleave(destination: labPlanarDestination)
```

For more information about working with planar buffers, see [Optimizing Image Processing Performance](https://developer.apple.com/documentation/accelerate/optimizing_image-processing_performance).

## Apply the hue adjustment

The app adjusts the hue of an image by rotating a two-element vector, described by _a\*_ and _b\*_. For more information about working with rotation matrices, see [Working with Matrices](https://developer.apple.com/documentation/accelerate/working_with_matrices).

The following visualizes a sample color (marked _A_) rotated by -90º (marked _C_) and 45º (marked _B_):

![A graphic showing a color rotated by minus 90 degrees and by 45 degrees. The background contains vertical and horizontal gradients. The colors transition from green on the left to red on the right, and from yellow at the top to blue at the bottom. The original color is light yellow. The color that is rotated minus 90 degrees is light green, and the color that is rotated 45 degrees is light red. ](Documentation/ColorRotate_2x.png)

The following code generates the rotation matrix based on `hueAngle`:

``` swift
let divisor: Int = 0x1000

let rotationMatrix = [
    1, 0,             0,
    0, cos(hueAngle), -sin(hueAngle),
    0, sin(hueAngle),  cos(hueAngle)
].map {
    return Int($0 * Float(divisor))
}
```

The `preBias` and `postBias` values effectively shift the _a\*_ and _b\*_ values from `0...255` to `-128...127`, so the rotation is centered where _a\*_ and _b\*_ are zero.

``` swift
let preBias = [Int](repeating: -128, count: 3)
let postBias = [Int](repeating: 128 * divisor, count: 3)
```

The [`multiply(by:divisor:preBias:postBias:destination:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951701-multiply) function multiplies each pixel in the source buffer by the matrix and writes the result to the destination buffers. The code performs the matrix multiplication in-place, so the source and destination point to the same buffers.

The following code performs the matrix multiply operation:

``` swift
labPlanarDestination.multiply(
    by: rotationMatrix,
    divisor: divisor,
    preBias: preBias,
    postBias: postBias,
    destination: labPlanarDestination)
```

On return, `labPlanarDestination` contains the hue-adjusted _a\*_ and _b\*_ channels.

## Display the image

Finally, the sample code converts the hue-adjusted planar buffer back to an interleaved buffer.

``` swift
labPlanarDestination.interleave(destination: labInterleavedDestination)
```

The SwiftUI [`Image`](https://developer.apple.com/documentation/swiftui/image) view supports the L\*a\*b\* color space. The following code creates a Core Graphics image from the interleaved pixel buffer and passes it to the published `outputImage` property that the app displays on the screen:

``` swift
if let result = labInterleavedDestination
    .makeCGImage(cgImageFormat: labImageFormat) {
    
    DispatchQueue.main.async {
        self.outputImage = result
    }
}
```
