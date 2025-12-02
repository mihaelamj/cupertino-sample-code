/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The file compressor app user interface file.
*/

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var compressor: Compressor
    
    @State private var isDropTargeted = false
    
    var body: some View {
        
        VStack {
            ZStack {
                Rectangle()
                    .fill(.tint)
                    .opacity(isDropTargeted || compressor.progress > 0 ? 1.0 : 0.5)
                    .dropDestination(for: URL.self) { receivedFiles, _ in
                        compressor.compress(urls: receivedFiles)
                    } isTargeted: {
                        isDropTargeted = $0
                    }
                
                ProgressView(value: compressor.progress,
                             total: compressor.totalUnitCount)
                    .padding()
                    .progressViewStyle(.circular)
                    .opacity(compressor.progress > 0 ? 1 : 0)
                
                Text("Drop files to compress or decompress.")
                    .padding()
                    .font(.title)
                    .opacity(compressor.progress > 0 ? 0 : 1)
            }
            .padding()
            
            Text(compressor.message)
        }
        .padding()
    }
}

