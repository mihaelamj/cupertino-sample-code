/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view showing the results of image registration.
*/

import SwiftUI

struct ContentView: View {

    // MARK: - View State
    // Controls the opacity of the aligned composite image.
    @State private var compositeOpacity: Double = 0.5
    
    // The mechanism for image registration.
    @State private var registrationMechanism = ImageRegistration.Mechanism.translational
    
    // Platform-agnostic images to use during image registration, and display in Views.
    @State private var referenceImage = PlatformImage(named: "Reference")!
    @State private var floatingImage = PlatformImage(named: "Warped")!
    @State private var alignedImage = PlatformImage()
    @State private var paddedReferenceImage = PlatformImage()

    // MARK: - View Building
    var body: some View {
        VStack {
            registrationImages
            registrationMechanismControl
            opacitySlider
        }.onAppear {
            // Register images when this view appears.
            registerImages()
        }
    }
    
    var registrationImages: some View {
        HStack {
            VStack {
                Text("Reference")
                    .lineLimit(1)
                Image(referenceImage)
                    .resizable()
                    .scaledToFit()
            }
            
            VStack {
                Text("Floating")
                    .lineLimit(1)
                Image(floatingImage)
                    .resizable()
                    .scaledToFit()
            }
            
            VStack {
                Text("Aligned Composite")
                    .lineLimit(1)
                ZStack {
                    Image(paddedReferenceImage)
                        .resizable()
                        .scaledToFit()
                    Image(alignedImage)
                        .resizable()
                        .scaledToFit()
                        .opacity(compositeOpacity)
                }
            }
        }.padding()
    }
    
    var registrationMechanismControl: some View {
        Picker("Registration Type", selection: $registrationMechanism) {
            ForEach(ImageRegistration.Mechanism.allCases) { mechanism in
                Text(mechanism.label)
                    .tag(mechanism)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .labelsHidden()
        .padding()
        // Register images whenever the registrationMechanism changes.
        .onChange(of: registrationMechanism.label) { (label) in
            registerImages()
        }
    }
    
    var opacitySlider: some View {
        VStack {
            Slider(value: $compositeOpacity,
                   minimumValueLabel: Text("Reference"),
                   maximumValueLabel: Text("Aligned Composite")) {
               Text("Opacity Slider")
                .lineLimit(1)
            }
            .labelsHidden()
            Text("Opacity")
                .lineLimit(1)
        }
        .padding()
    }
    
    // MARK: - Registration
    /// Performs an image registration request on the floating image and the reference image, then updates the
    /// composite image and padded reference image with the results.
    func registerImages() {
        ImageRegistration
            .shared.register(floatingImage: floatingImage,
                             referenceImage: referenceImage,
                             registrationMechanism: registrationMechanism) { composite, paddedReference in
                alignedImage = composite
                paddedReferenceImage = paddedReference
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
