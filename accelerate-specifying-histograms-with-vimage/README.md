# Specifying histograms with vImage

Calculate the histogram of one image, and apply it to a second image.

## Overview

_Histogram specification_ is an image-processing operation that calculates the histogram of a reference image and applies it to an input image. The operation changes the colors and tones of the input image to match those of the reference image.

The example below shows a source image (bottom left) and a histogram reference image (top left), with the histogram specification output on the right.

![Photos showing a source image of a lemon bloom, a histogram source image of brightly colored flowers, and histogram specified result. The histogram specified result contains the original image with the histogram source image colors.](Documentation/specification_2x.png)

Before exploring the code, build and run the app to familiarize yourself with the different visual results the app generates when you select different source and reference images.

## Perform histogram specification using pixel buffers

The [`vImage.PixelBuffer`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer) structure provides a simple API to calculate and specify a histogram. The [`histogram()`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951667-histogram) function returns the histogram of a pixel buffer, and the [`specifyHistogram(_:destination:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951785-specifyhistogram) function performs the histogram specification operation.

The following code creates the pixel buffers that the operation requires, performs the specification, and returns a Core Graphics image that contains the result:

``` swift
/// Performs a histogram specification operation using `vImage.PixelBuffer` structures.
static func applyHistogramSpecification_PixelBuffer(
    histogramSourceImage: CGImage,
    imageSourceImage: CGImage) -> CGImage {
        
        let histogramSource = try! vImage.PixelBuffer<vImage.Interleaved8x4>(
            cgImage: histogramSourceImage,
            cgImageFormat: &imageFormat)
        
        let imageSource = try! vImage.PixelBuffer<vImage.Interleaved8x4>(
            cgImage: imageSourceImage,
            cgImageFormat: &imageFormat)
        
        let destinationBuffer = vImage.PixelBuffer<vImage.Interleaved8x4>(
            size: imageSource.size)
        
        let histogram = histogramSource.histogram()
        
        imageSource.specifyHistogram(histogram, destination: destinationBuffer)
        
        return destinationBuffer.makeCGImage(cgImageFormat: imageFormat)!
    }
```

## Calculate the reference histogram using vImage buffers

If you're creating apps for older operating systems that don't support the [`vImage.PixelBuffer`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer) API, the sample code project also includes source code for performing histogram specification using [`vImage_Buffer`](https://developer.apple.com/documentation/accelerate/vimage_buffer) structures.

The [`vImageHistogramCalculation_ARGB8888(_:_:_:)`](https://developer.apple.com/documentation/accelerate/1545743-vimagehistogramcalculation_argb8) calculates and stores histogram data in four arrays — one for each channel — where the value of each element is the number of pixels in the reference image with that color value. In an 8-bit-per-channel image, each color channel can hold 256 different values, and the sample code defines each array with a count of 256.

``` swift
var histogramBinZero = [vImagePixelCount](repeating: 0, count: 256)
var histogramBinOne = [vImagePixelCount](repeating: 0, count: 256)
var histogramBinTwo = [vImagePixelCount](repeating: 0, count: 256)
var histogramBinThree = [vImagePixelCount](repeating: 0, count: 256)
```

The following code calculates the histogram of the `histogramSource` [`vImage_Buffer`](https://developer.apple.com/documentation/accelerate/vimage_buffer) structure:

``` swift
histogramBinZero.withUnsafeMutableBufferPointer { zeroPtr in
    histogramBinOne.withUnsafeMutableBufferPointer { onePtr in
        histogramBinTwo.withUnsafeMutableBufferPointer { twoPtr in
            histogramBinThree.withUnsafeMutableBufferPointer { threePtr in
                
                var histogramBins = [zeroPtr.baseAddress, onePtr.baseAddress,
                                     twoPtr.baseAddress, threePtr.baseAddress]
                
                histogramBins.withUnsafeMutableBufferPointer { histogramBinsPtr in
                    let error = vImageHistogramCalculation_ARGB8888(&histogramSource,
                                                                    histogramBinsPtr.baseAddress!,
                                                                    vImage_Flags(kvImageNoFlags))
                    
                    guard error == kvImageNoError else {
                        fatalError("Error calculating histogram: \(error)")
                    }
                }
            }
        }
    }
}
```

On return, the four arrays contain the histogram data from the `histogramSource`.

## Specify the image histogram using vImage buffers

The [`vImageHistogramSpecification_ARGB8888`](https://developer.apple.com/documentation/accelerate/1546963-vimagehistogramspecification_arg) performs the histogram specification operation. The following code matches the histogram of the reference image to the input image:

``` swift
histogramBinZero.withUnsafeBufferPointer { zeroPtr in
    histogramBinOne.withUnsafeBufferPointer { onePtr in
        histogramBinTwo.withUnsafeBufferPointer { twoPtr in
            histogramBinThree.withUnsafeBufferPointer { threePtr in
                
                var histogramBins = [zeroPtr.baseAddress, onePtr.baseAddress,
                                     twoPtr.baseAddress, threePtr.baseAddress]
                
                histogramBins.withUnsafeMutableBufferPointer { histogramBinsPtr in
                    let error = vImageHistogramSpecification_ARGB8888(&imageSource,
                                                                      &destinationBuffer,
                                                                      histogramBinsPtr.baseAddress!,
                                                                      vImage_Flags(kvImageNoFlags))
                    
                    guard error == kvImageNoError else {
                        fatalError("Error specifying histogram: \(error)")
                    }
                }
            }
        }
    }
}
```

On return, `destinationBuffer` contains the original input image with the histogram that the reference image specified.
