# Converting luminance and chrominance planes to an ARGB image

Create a displayable ARGB image using the luminance and chrominance information from your device's camera.

## Overview

As an alternative to the any-to-any conversion technique that [Using vImage Pixel Buffers to Generate Video Effects](https://developer.apple.com/documentation/accelerate/using_vimage_pixel_buffers_to_generate_video_effects) describes, vImage provides low-level functions for creating RGB images from the separate luminance and chrominance planes that an [`AVCaptureSession`](https://developer.apple.com/documentation/avfoundation/avcapturesession) instance provides. These functions offer better performance and more granular configuration than using a [`vImageConverter`](https://developer.apple.com/documentation/accelerate/vimageconverter) instance.

## Configure the YpCbCr-to-ARGB information

The [`vImageConvert_YpCbCrToARGB_GenerateConversion(_:_:_:_:_:_:)`](https://developer.apple.com/documentation/accelerate/1533189-vimageconvert_ypcbcrtoargb_gener) function 
generates the information that vImage requires to convert the luminance and chrominance planes to a single ARGB image. 

Video-range YpCbCr formats often don't use very low and very high values. For example, an 8-bit 
video range format typically uses the range `16...235` for luminance and `16...240` for chrominance. 
The generate conversion function accepts a [`vImage_YpCbCrPixelRange`](https://developer.apple.com/documentation/accelerate/vimage_ypcbcrpixelrange) structure that defines the pixel range.

The following code example populates a [`vImage_YpCbCrToARGB`](https://developer.apple.com/documentation/accelerate/vimage_ypcbcrtoargb) structure with the required conversion information for video-range 8-bit pixels:

``` swift
var infoYpCbCrToARGB = vImage_YpCbCrToARGB()

func configureYpCbCrToARGBInfo() {
    var pixelRange = vImage_YpCbCrPixelRange(Yp_bias: 16,
                                             CbCr_bias: 128,
                                             YpRangeMax: 235,
                                             CbCrRangeMax: 240,
                                             YpMax: 235,
                                             YpMin: 16,
                                             CbCrMax: 240,
                                             CbCrMin: 16)

    var ypCbCrToARGBMatrix = vImage_YpCbCrToARGBMatrix(Yp: 1.0,
                                                       Cr_R: 1.402, Cr_G: -0.7141363,
                                                       Cb_G: -0.3441363, Cb_B: 1.772)
    
    _ = vImageConvert_YpCbCrToARGB_GenerateConversion(
        &ypCbCrToARGBMatrix,
        &pixelRange,
        &infoYpCbCrToARGB,
        kvImage422CbYpCrYp8,
        kvImageARGB8888,
        vImage_Flags(kvImageNoFlags))
}
```

## Lock the Core Video pixel buffer

Before the sample app accesses the pixel data that AVFoundation supplies as a [`CVPixelBuffer`](https://developer.apple.com/documentation/corevideo/cvpixelbuffer-q2e), it calls [`CVPixelBufferLockBaseAddress(_:_:)`](https://developer.apple.com/documentation/corevideo/cvpixelbufferlockbaseaddress(_:_:)) to lock the pixel buffer and make the underlying memory available.

After the YpCbCr-to-RGB conversion is complete, the code calls [`CVPixelBufferUnlockBaseAddress(_:_:)`](https://developer.apple.com/documentation/corevideo/cvpixelbufferunlockbaseaddress(_:_:)) to unlock the pixel buffer.

The `convertYpCbCrToRGB(cvPixelBuffer:)` function performs the YpCbCr-to-RGB conversion. 

``` swift
CVPixelBufferLockBaseAddress(
    pixelBuffer,
    CVPixelBufferLockFlags.readOnly)

convertYpCbCrToRGB(cvPixelBuffer: pixelBuffer)

CVPixelBufferUnlockBaseAddress(
    pixelBuffer,
    CVPixelBufferLockFlags.readOnly)
```

## Create the source luminance and chrominance pixel buffers

The `convertYpCbCrToRGB(cvPixelBuffer:)` function creates two pixel buffers that share memory with 
the [`CVPixelBuffer`](https://developer.apple.com/documentation/corevideo/cvpixelbuffer-q2e). The Core Video pixel 
buffer contains two planes: the plane at index `0` contains one channel that represents the luminance component, 
the plane at index `1` contains two interleaved channels that represent the two chrominance components.

The [`init(referencing:planeIndex:overrideSize:pixelFormat:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951692-init) function initializes a [`vImage.PixelBuffer`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer) that references a single plane of a multiple-plane Core Video pixel buffer.

``` swift
let lumaPixelBuffer = vImage.PixelBuffer(referencing: cvPixelBuffer,
                                         planeIndex: 0,
                                         pixelFormat: vImage.Planar8.self)

let chromaPixelBuffer = vImage.PixelBuffer(referencing: cvPixelBuffer,
                                           planeIndex: 1,
                                           pixelFormat: vImage.Interleaved8x2.self)
```

## Adjust the contrast of the image

The sample app provides a [`Slider`](https://developer.apple.com/documentation/swiftui/slider) for changing the contrast of the final image. The following code example uses the tone-mapping 
technique that [Adjusting saturation and applying tone mapping](https://developer.apple.com/documentation/accelerate/adjusting_saturation_and_applying_tone_mapping) describes:

``` swift
if contrast != 1 {
    lumaPixelBuffer.applyGamma(.halfPrecision(contrast),
                               destination: lumaPixelBuffer)
}
```

## Convert the YpCbCr image to an ARGB image 

The [`convert(lumaSource:chromaSource:conversionInfo:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951606-convert) converts the luminance and chrominance information in `lumaPixelBuffer` and `chromaPixelBuffer` to an ARGB image. This pixel buffer method calls the underlying vImage [`vImageConvert_420Yp8_CbCr8ToARGB8888(_:_:_:_:_:_:_:)`](https://developer.apple.com/documentation/accelerate/1533095-vimageconvert_420yp8_cbcr8toargb) function.

``` swift
    
argbPixelBuffer.convert(lumaSource: lumaPixelBuffer,
                        chromaSource: chromaPixelBuffer,
                        conversionInfo: infoYpCbCrToARGB)
```
