/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the selected image and its results based on the Vision requests.
*/

import SwiftUI

struct SelfieResultsView: View {
    var selfie: Selfie
    
    @State private var showingFaceRectangle = false
    @State private var showingFaceLandmarks = false
    
    var body: some View {
        VStack {
            /// Display the capture-quality score of the selfie.
            Text("Score: \(selfie.score, specifier: "%.2f")")
                .foregroundStyle(.gray)
                .font(.headline)
            
            /// Display the number of faces `Vision` detects in the selfie.
            Text("Faces Detected: \(selfie.facesDetected)")
                .foregroundStyle(.gray)
                .font(.headline)
            
            if let image = UIImage(data: selfie.photo) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay {
                        /// Overlay the facial rectangle on the image if the option is toggled.
                        if showingFaceRectangle {
                            ForEach(selfie.landmarksResults, id: \.self) { observation in
                                BoundingBox(observation: observation)
                                    .stroke(.red, lineWidth: 2)
                            }
                        }
                        
                        /// Overlay the facial landmarks on the image if the option is toggled.
                        if showingFaceLandmarks {
                            ForEach(selfie.landmarksResults, id: \.self) { observation in
                                FaceLandmark(region: observation.landmarks!.faceContour)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.innerLips)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.leftEye)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.leftEyebrow)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.leftPupil)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.medianLine)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.nose)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.noseCrest)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.outerLips)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.rightEye)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.rightEyebrow)
                                    .stroke(.white, lineWidth: 2)
                                FaceLandmark(region: observation.landmarks!.rightPupil)
                                    .stroke(.white, lineWidth: 2)
                            }
                        }
                    }
            }
            
            /// The options to enable or disable the facial bounding boxes and landmarks.
            VStack {
                Toggle("Show Face Rectangles", isOn: $showingFaceRectangle)
                    .tint(.blue)
                    .frame(width: 300)
                    .padding(5)
                    .foregroundStyle(.gray)
                    
                Toggle("Show Face Landmarks", isOn: $showingFaceLandmarks)
                    .tint(.blue)
                    .frame(width: 300)
                    .padding(5)
                    .foregroundStyle(.gray)
            }
        }
    }
}
