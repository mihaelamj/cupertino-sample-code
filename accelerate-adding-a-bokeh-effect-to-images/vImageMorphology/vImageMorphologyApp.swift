/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The MorphologyTransformer application file.
*/

import SwiftUI

@main
struct vImageMorphologyApp: App {
    
    @StateObject private var morphologyTransformer = MorphologyTransformer(sourceImage: #imageLiteral(resourceName: "Food_4.JPG"))
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(morphologyTransformer)
        }
    }
}
