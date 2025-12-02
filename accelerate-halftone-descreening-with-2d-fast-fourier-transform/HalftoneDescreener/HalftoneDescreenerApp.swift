/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
FFT halftone descreener application.
*/

import SwiftUI

@main
struct HalftoneDescreenerApp: App {
    
    static let sourceImage: CGImage! = {
        let img = #imageLiteral(resourceName: "Flowers_1024_10.jpg")
        
        return img.cgImage(forProposedRect: nil,
                           context: nil,
                           hints: nil)
    }()
    
   static let halftoneImage: CGImage! = {
        let img = #imageLiteral(resourceName: "HalftoneScreen_1024_10.jpg")
        
        return img.cgImage(forProposedRect: nil,
                           context: nil,
                           hints: nil)
    }()
    
    @StateObject private var halftoneDescreener = HalftoneDescreener(sourceImage: Self.sourceImage,
                                                                     halftoneImage: Self.halftoneImage)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(halftoneDescreener)
        }
    }
}
