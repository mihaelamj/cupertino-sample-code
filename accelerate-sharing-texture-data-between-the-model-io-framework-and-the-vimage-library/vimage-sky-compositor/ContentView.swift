/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sky compositor user interface file.
*/

import SwiftUI

struct ContentView: View {
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    static func format(_ value: Float) -> String {
        Self.formatter.string(from: value as NSNumber)!
    }

    @EnvironmentObject var imageProvider: ImageProvider
    
    var body: some View {
                
        VStack {
            Image(decorative: imageProvider.outputImage, scale: 1)
   
            Grid {
                GridRow {
                    Text("Turbidity").gridColumnAlignment(.trailing)
                    
                    Picker("Turbidity", selection: $imageProvider.turbidity) {
                        ForEach(ImageProvider.options, id: \.self) {
                            Text("\(Self.format($0))")
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                GridRow {
                    Text("Sun Elevation")
                    
                    Picker("Sun Elevation", selection: $imageProvider.sunElevation) {
                        ForEach(ImageProvider.options, id: \.self) {
                            Text("\(Self.format($0))")
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                GridRow {
                    Text("Upper Atmosphere Scattering")
                    
                    Picker("Upper Atmosphere Scattering", selection: $imageProvider.upperAtmosphereScattering) {
                        ForEach(ImageProvider.options, id: \.self) {
                            Text("\(Self.format($0))")
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                GridRow {
                    Text("Ground Albedo")
                    
                    Picker("Ground Albedo", selection: $imageProvider.groundAlbedo) {
                        ForEach(ImageProvider.options, id: \.self) {
                            Text("\(Self.format($0))")
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                GridRow {
                    Text("View")
                    
                    Picker("View", selection: $imageProvider.view) {
                        ForEach(ImageProvider.views, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            .padding()

        }
        .padding()
        .disabled(imageProvider.isBusy)
        .overlay {
            ProgressView()
                .opacity(imageProvider.isBusy ? 1 : 0)
        }
        
    }
}
