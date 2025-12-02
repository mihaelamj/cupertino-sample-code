/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to NSImage that saves the image to a specific location in PNG format.
*/

import Cocoa

extension NSImage {

    func savePNGToDisk(at url: URL) {
        if let tiffData = self.tiffRepresentation,
            let bitmapImageRep = NSBitmapImageRep(data: tiffData),
            let pngData = bitmapImageRep.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: url)
            } catch {
                print(error)
            }
        }
    }

}
