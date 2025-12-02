/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ContentView class that returns a `CIImage` for the current time.
*/

import SwiftUI
import CoreImage.CIFilterBuiltins

/// - Tag: ContentView
struct ContentView: View {
    var body: some View {
        // Create a Metal view with its own renderer.
        let renderer = Renderer(imageProvider: { (time: CFTimeInterval, scaleFactor: CGFloat, headroom: CGFloat) -> CIImage in
            
            var image: CIImage
            
            // Animate a shifting red and yellow checkerboard pattern.
            let pointsShiftPerSecond = 25.0
            let checkerFilter = CIFilter.checkerboardGenerator()
            checkerFilter.width = 20.0 * Float(scaleFactor)
            checkerFilter.color0 = CIColor.red
            checkerFilter.color1 = CIColor.yellow
            checkerFilter.center = CGPoint(x: time * pointsShiftPerSecond, y: time * pointsShiftPerSecond)
            image = checkerFilter.outputImage ?? CIImage.empty()
            
            // Animate the hue of the image with time.
            let colorFilter = CIFilter.hueAdjust()
            colorFilter.inputImage = image
            colorFilter.angle = Float(time)
            image = colorFilter.outputImage ?? CIImage.empty()

            // Compute a shading image for the ripple effect below.
            // Cast light on the upper-left corner of the shading gradient image.
            let angle = 135.0 * (.pi / 180.0)
            let gradient = CIFilter.linearGradient()
            // Create a bright white color for a specular highlight with the current
            // maximum possible pixel component values within headroom
            // or a reasonable alternative.
            let maxRGB = min(headroom, 8.0)
            gradient.color0 = CIColor(red: maxRGB, green: maxRGB, blue: maxRGB,
                                      colorSpace: CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!)!
            gradient.color1 = CIColor.clear
            gradient.point0 = CGPoint(x: sin(angle) * 90.0 + 100.0,
                                      y: cos(angle) * 90.0 + 100.0)
            gradient.point1 = CGPoint(x: sin(angle) * 85.0 + 100.0,
                                      y: cos(angle) * 85.0 + 100.0)
            let shading = gradient.outputImage?.cropped(to: CGRect(x: 0, y: 0,
                                                                   width: 200, height: 200))
            
            // Add a shiny ripple effect to the image.
            let ripple = CIFilter.rippleTransition()
            ripple.inputImage = image
            ripple.targetImage = image
            ripple.center = CGPoint(x: 256.0 * scaleFactor,
                                    y: 192.0 * scaleFactor)
            ripple.time = Float(fmod(time * 0.25, 1.0))
            ripple.shadingImage = shading
            image = ripple.outputImage ?? CIImage()
            
            return image.cropped(to: CGRect(x: 0, y: 0,
                                            width: 512.0 * scaleFactor,
                                            height: 384.0 * scaleFactor))
        })

        MetalView(renderer: renderer)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
