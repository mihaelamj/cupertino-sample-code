/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The user interface for polynomial transform app.
*/

import SwiftUI
import Accelerate
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var polynomialTransformer: PolynomialTransformer
    @State private var selectNewImage = false

    var body: some View {
        HSplitView {
            VStack {
                Image(decorative: polynomialTransformer.outputImage, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .frame(minWidth: 600, minHeight: 400)
                Text(imageLabel)
                    .font(.footnote)
            }
            
            VStack {
                // Red
                PolynomialEditor(
                    title: "Red",
                    color: .red,
                    values: $polynomialTransformer.redHandleValues,
                    coefficients: $polynomialTransformer.redCoefficients)

                Divider()

                // Green
                PolynomialEditor(
                    title: "Green",
                    color: .green,
                    values: $polynomialTransformer.greenHandleValues,
                    coefficients: $polynomialTransformer.greenCoefficients)

                Divider()

                // Blue
                PolynomialEditor(
                    title: "Blue",
                    color: .blue,
                    values: $polynomialTransformer.blueHandleValues,
                    coefficients: $polynomialTransformer.blueCoefficients)

            }
            .frame(minWidth: 400)
            .padding()
        }
        .toolbar {
            ToolbarItem {
                Button("Select Image...", action: { selectNewImage = true })
                    .fileImporter(
                        isPresented: $selectNewImage,
                        allowedContentTypes: [.png, .jpeg, .heic]) { result in
                        if case .success(let url) = result {
                            polynomialTransformer.sourceImage = NSImage(byReferencing: url)
                        }
                    }
            }
        }
    }

    var imageLabel: String {
        let model = PolynomialTransformer.sourceImageFormat.colorSpace.takeRetainedValue().name
        return
            "\(model ?? "[unknown color space]" as CFString) | " +
            "\(Int(polynomialTransformer.sourceImage.size.width)) x " +
            "\(Int(polynomialTransformer.sourceImage.size.height))"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(PolynomialTransformer())
    }
}
