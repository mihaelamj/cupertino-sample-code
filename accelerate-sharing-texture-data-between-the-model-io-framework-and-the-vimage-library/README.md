# Sharing texture data between the Model I/O framework and the vImage library

Use Model I/O and vImage to composite a photograph over a
computer-generated sky.

## Overview

The [Model I/O](https://developer.apple.com/documentation/modelio)
framework provides the
[`MDLTexture`](https://developer.apple.com/documentation/modelio/mdltexture) 
class and its subclasses to generate procedural textures
such as noise, normal maps, and realistic sky boxes.  This sample code
project uses an
[`MDLSkyCubeTexture`](https://developer.apple.com/documentation/modelio/mdlskycubetexture) 
instance to generate a physically realistic simulation
of a sunlit sky. The code uses the generated sky image as the background
and a photograph of a building as the foreground.

The image below shows the final composition:

![A photograph of a skyscraper composited over a computer-generated
background image of a hazy sky.](Documentation/img.png)

Using the UI, someone can define the parameters that control
the sky simulation such as upper atmosphere scattering and sun
elevation. Before exploring the code, try building and running the app
to get familiar with the effect of the different parameters on
the image.

## Create the sky texture generator

The `ImageProvider` class declares constants for the source image's
dimensions and the 
[`MDLSkyCubeTexture`](https://developer.apple.com/documentation/modelio/mdlskycubetexture) instance named `skyGenerator`:

``` swift
let width: Int
var height: Int

let skyGenerator: MDLSkyCubeTexture
```

The initializer creates the sky generator instance that's the same size
as the top layer image of the skyscraper:

``` swift
width = foregroundImage.width
height = foregroundImage.height

skyGenerator = MDLSkyCubeTexture(name: nil,
                                 channelEncoding: .uInt8,
                                 textureDimensions: .init(x: Int32(width),
                                                          y: Int32(height)),
                                 turbidity: 0,
                                 sunElevation: 0,
                                 upperAtmosphereScattering: 0,
                                 groundAlbedo: 0)
```

## Update the sky texture generator parameters

With each change to the SwiftUI
[Picker](https://developer.apple.com/documentation/swiftui/picker)
controls that define the sky generator parameters, the app calls the
`renderSky()` function. The function sets the sky generator parameters
and calls
[`update`](https://developer.apple.com/documentation/modelio/mdlskycubetexture/1391548-update) to generate new texel data:

``` swift
skyGenerator.turbidity = turbidity
skyGenerator.sunElevation = sunElevation
skyGenerator.upperAtmosphereScattering = upperAtmosphereScattering
skyGenerator.groundAlbedo = groundAlbedo

skyGenerator.update()
```

## Create the composite image

The
[`texelDataWithTopLeftOrigin()`](https://developer.apple.com/documentation/modelio/mdltexture/1391666-texeldatawithtopleftorigin) 
method returns the sky generator's image data organized such that its first pixel
represents the top-left corner of the image. This layout matches the
[`vImage.PixelBuffer`](`https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer`) layout. 
The code passes the texel data to the
[`withUnsafeBytes(_:)`](https://developer.apple.com/documentation/foundation/data/3139154-withunsafebytes) 
function to work with the underlying bytes of the data's contiguous storage.

``` swift
let img = skyGenerator.texelDataWithTopLeftOrigin()?.withUnsafeBytes { skyData in
```

The
[`MDLSkyCubeTexture`](https://developer.apple.com/documentation/modelio/mdlskycubetexture) 
instance generates a cube texture that's represented as six sides, vertically stacked.

![A vertically stacked series of six images that represent the six sides of the sky texture cube.](Documentation/cube.png)

The code below calculates the range texels that correspond to the
selected side (one of `["+X", "-X", "+Y", "-Y", "+Z", "-Z"]`) and binds
those to [`Pixel_8`](https://developer.apple.com/documentation/accelerate/pixel_8) 
values:

``` swift
let imageIndex = ImageProvider.views.firstIndex(of: view) ?? 0
let imagePixelCount = width * height * format.componentCount

let range = imageIndex * imagePixelCount ..< (imageIndex + 1) * imagePixelCount

let values = skyData.bindMemory(to: Pixel_8.self)[ range ]
```

The code below creates a
[`vImage.PixelBuffer`](`https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer`)
structure from the values and, because the
[`alphaComposite(_:topLayer:destination:)`](https://developer.apple.com/documentation/accelerate/vimage/pixelbuffer/3951566-alphacomposite) 
method expects ARGB data, permutes the channel order so that alpha channel is first:

``` swift
let buffer = vImage.PixelBuffer(pixelValues: values,
                                size: .init(width: width, height: height),
                                pixelFormat: vImage.Interleaved8x4.self)

buffer.permuteChannels(to: (3, 0, 1, 2), destination: buffer)
```

Finally, the sample code project composites the skyscraper image,
represented by `foregroundBuffer`, over the sky image and returns a
[`CGImage`](https://developer.apple.com/documentation/coregraphics/cgimage) 
instance that contains the result:

``` swift
    buffer.alphaComposite(.nonpremultiplied,
                          topLayer: foregroundBuffer,
                          destination: buffer)
    
    return buffer.makeCGImage(cgImageFormat: format)
} // Ends `skyGenerator.texelDataWithTopLeftOrigin()?.withUnsafeBytes`.
```
