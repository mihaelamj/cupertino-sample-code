/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Accelerate k-means user-interface file.
*/

import SwiftUI
import SceneKit

struct ContentView: View {
    
    @EnvironmentObject var kMeansCalculator: KMeansCalculator
    
    var body: some View {
        
        NavigationSplitView {
            List(kMeansCalculator.sourceImages,
                 selection: $kMeansCalculator.selectedThumbnail) { thumbnail in
                Image(decorative: thumbnail.thumbnail,
                      scale: 1)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onTapGesture {
                    kMeansCalculator.selectedThumbnail = thumbnail
                }
                .border(kMeansCalculator.selectedThumbnail == thumbnail ? .blue : .gray,
                        width: 4)
                .disabled(kMeansCalculator.isBusy)
            }
        } detail: {
            
            Divider()
            
            HStack {
                TabView {
                    Image(decorative: kMeansCalculator.sourceImage, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tabItem {
                            Label("Original image", systemImage: "photo")
                        }
                    
                    Image(decorative: kMeansCalculator.quantizedImage, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tabItem {
                            Label("Quantized image (\(dimension) x \(dimension))",
                                  systemImage: "photo")
                        }
                }
                .opacity(kMeansCalculator.isBusy ? 0.5 : 1)
                .disabled(kMeansCalculator.isBusy)
                .overlay {
                    ProgressView()
                        .opacity(kMeansCalculator.isBusy ? 1 : 0)
                }
                
                Divider()
                
                SceneView(
                    scene: kMeansCalculator.scene,
                    pointOfView: nil,
                    options: [.allowsCameraControl, .autoenablesDefaultLighting]
                )
                .opacity(kMeansCalculator.isBusy ? 0.5 : 1)
                .overlay {
                    ProgressView()
                        .opacity(kMeansCalculator.isBusy ? 1 : 0)
                }
            }
            .padding()
            
            Divider()
            
            HStack {
                ForEach(kMeansCalculator.dominantColors.sorted(by: >)) { dominantColor in
                    VStack {
                        RoundedRectangle(cornerSize: .init(width: 5, height: 5))
                            .fill(dominantColor.color)
                            .frame(height: 50)
                        Text("\(dominantColor.percentage)%")
                            .opacity(dominantColor.percentage == 0 ? 0 : 1)
                    }
                }
            }
            .padding()
            .opacity(kMeansCalculator.isBusy ? 0 : 1)
            
            Divider()
            
            HStack {
                
                Picker("Number of centroids", selection: $kMeansCalculator.k) {
                    ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], id: \.self) {
                        Text("\($0)")
                    }
                }
                .pickerStyle(.segmented)
                .disabled(kMeansCalculator.isBusy)
                
                Spacer()
               
                Button("Run again") {
                    kMeansCalculator.calculateKMeans()
                }
                .disabled(kMeansCalculator.isBusy)
            }
            .padding()
        }
        .padding()
    }
}
