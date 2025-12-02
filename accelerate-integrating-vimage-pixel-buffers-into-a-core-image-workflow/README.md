# Integrating vImage pixel buffers into a Core Image workflow

Share image data between Core Video pixel buffers and vImage buffers to integrate vImage operations into a Core Image workflow.

## Overview

vImage supports reading from and writing to Core Video pixel buffers. This sample implements ends-in contrast stretching using vImage and makes that operation available to Core Image workflows by subclassing [`CIImageProcessorKernel`](https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel). An image processor kernel uses Core Video pixel buffers for input and output, so the app creates vImage pixel buffers that share data with [`CVPixelBuffer`](https://developer.apple.com/documentation/corevideo/cvpixelbuffer) instances.

The example below shows a photograph before (left) and after (right) the app has applied ends-in contrast stretching:

![A side-by-side comparison of the original close-up image of some flowers with its contrast-stretched counterpart.](Documentation/stretch_2x.jpg)

To learn more about ends-in contrast stretching, see [Enhancing image contrast with histogram manipulation](https://developer.apple.com/documentation/accelerate/enhancing_image_contrast_with_histogram_manipulation#3701605).

Before exploring the code, try building and running the app to familiarize yourself with the effect of the different parameters on the image.

## Define an ends-in contrast-stretch image processor kernel

The `ContrastStretchImageProcessorKernel` inherits from the Core Image [`CIImageProcessorKernel`](https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel) class.

The sample code defines a [`vImage_CGImageFormat`](https://developer.apple.com/documentation/accelerate/vimage_cgimageformat) structure that represents a four-channel, 8-bit-per-channel interleaved image format. The image processor kernel supports [`kCIFormatR8`](https://developer.apple.com/documentation/coreimage/ciformat/1437695-r8), [`kCIFormatBGRA8`](https://developer.apple.com/documentation/coreimage/ciformat/1438064-bgra8), [`kCIFormatRGBAh`](https://developer.apple.com/documentation/coreimage/ciformat/1437998-rgbah), and [`kCIFormatRGBAf`](https://developer.apple.com/documentation/coreimage/ciformat/1437756-rgbaf) input and output formats. For this sample project, the code overrides [`outputFormat`](https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel/2143065-outputformat) and [`formatForInput(at:)`](https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel/2138289-formatforinput) to return a `BGRA8` that's the same as the [`bitmapInfo`](https://developer.apple.com/documentation/accelerate/vimage_cgimageformat/1399030-bitmapinfo) property of the `vImage_CGImageFormat` structure.

``` swift
static var cgImageFormat = vImage_CGImageFormat(
    bitsPerComponent: 8,
    bitsPerPixel: 32,
    colorSpace: nil,
    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
    version: 0,
    decode: nil,
    renderingIntent: .defaultIntent)

override class var outputFormat: CIFormat {
    return CIFormat.BGRA8
}

override class func formatForInput(at input: Int32) -> CIFormat {
    return CIFormat.BGRA8
}
```

## Create the source pixel buffer

When the app applies ends-in contrast stretching, Core Image calls the processor kernel's [`process(with:arguments:output:)`](https://developer.apple.com/documentation/coreimage/ciimageprocessorkernel/2138290-process) function. The following code ensures that the input and output [`CVPixelBuffer`](https://developer.apple.com/documentation/corevideo/cvpixelbuffer) instances are available:

``` swift
guard
    let input = inputs?.first,
    let inputPixelBuffer = input.pixelBuffer,
    let outputPixelBuffer = output.pixelBuffer else {
        return
}
```

The source [`vImage.PixelBuffer`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer) shares its memory with the input [`CVPixelBuffer`](https://developer.apple.com/documentation/corevideo/cvpixelbuffer). The following code creates a [`vImageConverter`](https://developer.apple.com/documentation/accelerate/vimageconverter) that allows the pixel buffer to reference the Core Video buffer's memory:

``` swift
CVPixelBufferLockBaseAddress(inputPixelBuffer,
                             CVPixelBufferLockFlags.readOnly)
defer {
    CVPixelBufferUnlockBaseAddress(inputPixelBuffer,
                                   CVPixelBufferLockFlags.readOnly)
}

guard let cvImageFormat = vImageCVImageFormat.make(buffer: inputPixelBuffer) else {
    throw ContrastStretchImageProcessorKernelError.unableToDeriveImageFormat
}

if cvImageFormat.colorSpace == nil {
    cvImageFormat.colorSpace = CGColorSpaceCreateDeviceRGB()
}

guard let converter = try? vImageConverter.make(
    sourceFormat: cvImageFormat,
    destinationFormat: cgImageFormat) else {
    throw ContrastStretchImageProcessorKernelError.vImageConverterCreationFailed
}

let sourcePixelBuffer = vImage.PixelBuffer<vImage.Interleaved8x4>(
    referencing: inputPixelBuffer,
    converter: converter)
```

## Create the destination pixel buffer

The sample code app uses the same [`vImageConverter`](https://developer.apple.com/documentation/accelerate/vimageconverter) to create the destination pixel buffer, which shares memory with the output Core Video buffer's memory.

``` swift
CVPixelBufferLockBaseAddress(outputPixelBuffer,
                             CVPixelBufferLockFlags.readOnly)
defer {
    CVPixelBufferUnlockBaseAddress(outputPixelBuffer,
                                   CVPixelBufferLockFlags.readOnly)
}

let destinationPixelBuffer = vImage.PixelBuffer<vImage.Interleaved8x4>(
    referencing: outputPixelBuffer,
    converter: converter)
```

## Apply ends-in contrast stretching

The [`vImageEndsInContrastStretch_ARGB8888(_:_:_:_:_:)`](https://developer.apple.com/documentation/accelerate/1545003-vimageendsincontraststretch_argb) function applies an ends-in contrast-stretch operation to the source pixel buffer and writes the result to the destination pixel buffer. This function works equally well on all channel orderings; for example, RGBA or BGRA.

``` swift
let error = sourcePixelBuffer.withUnsafePointerToVImageBuffer { src in
    destinationPixelBuffer.withUnsafePointerToVImageBuffer { dst in

        return vImageEndsInContrastStretch_ARGB8888(
            src,
            dst,
            [UInt32](repeating: UInt32(percentLow), count: 4),
            [UInt32](repeating: UInt32(percentHigh), count: 4),
            vImage_Flags(kvImageNoFlags))
        
    }
}
```

Because the destination pixel buffer shares memory with the output Core Video pixel buffer, the operation is complete after the [`vImageEndsInContrastStretch_ARGB8888(_:_:_:_:_:)`](https://developer.apple.com/documentation/accelerate/1545003-vimageendsincontraststretch_argb) returns.

## Apply the ends-in contrast stretching operation to an image

The  `apply(withExtent:inputs:arguments:)` method generates a [`CIImage`](https://developer.apple.com/documentation/coreimage/ciimage) instance based on the output of the processor's `process(with:arguments:output:)` function.

``` swift
let ciResult = try? ContrastStretchImageProcessorKernel.apply(
    withExtent: ciImage.extent,
    inputs: [ciImage],
    arguments: ["percentLow": Int(percentLow),
                "percentHigh": Int(percentHigh)])
```
