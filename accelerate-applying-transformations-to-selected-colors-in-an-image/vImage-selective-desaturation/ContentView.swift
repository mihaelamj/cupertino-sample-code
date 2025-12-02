/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The selective desaturator UI file.
*/

import SwiftUI

struct ContentView: View {
    
    func reset() {
        selectiveDesaturator.targetColor = .black
    }

    @EnvironmentObject var selectiveDesaturator: SelectiveDesaturator

    let swatchImageScale = CGFloat(2)
    
    var body: some View {
        VStack {
            
            HStack {
               
                VStack {
                    // The source image.
                    Image(decorative: selectiveDesaturator.sourceImage,
                          scale: swatchImageScale)
                    .aspectRatio(contentMode: .fit)
                    .onHover(perform: { hovering in
                        if hovering {
                            NSCursor.crosshair.push()
                        } else {
                            NSCursor.pop()
                        }
                    })
                    .onTapGesture { location in
               
                        let index = Int(location.x * swatchImageScale) + Int(location.y * swatchImageScale) * selectiveDesaturator.sourceImage.width
                        
                        let color = CGColor(red: CGFloat(selectiveDesaturator.sourcePixelsRed[index]),
                                            green: CGFloat(selectiveDesaturator.sourcePixelsGreen[index]),
                                            blue: CGFloat(selectiveDesaturator.sourcePixelsBlue[index]),
                                            alpha: 1)
                        
                        selectiveDesaturator.targetColor = color
                    }
                    Rectangle()
                        .foregroundColor(Color(cgColor: selectiveDesaturator.targetColor))
                        .frame(width: CGFloat(selectiveDesaturator.sourceImage.width) / swatchImageScale,
                               height: 50)
                }
       
                // The transformed image.
                Image(decorative: selectiveDesaturator.outputImage,
                      scale: 1)
                .aspectRatio(contentMode: .fit)
            }
            .padding()
        }
            
            Divider()
            
            HStack {

                Toggle(isOn: $selectiveDesaturator.desaturate) {
                    Text("Desaturate")
                }
                
                Toggle(isOn: $selectiveDesaturator.darken) {
                    Text("Darken")
                }
            
                Spacer()
   
                Picker("Tolerance", selection: $selectiveDesaturator.tolerance) {
                    ForEach([50, 100, 200] as [Float], id: \.self) {
                        Text("\(Int($0))")
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                Button("Reset", action: reset)
            }
            .padding()
        }
    }
