/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that draws the strokes to the canvas and responds to user input.
*/

import SwiftUI

struct CanvasView: View {
    @ObservedObject var canvas: Canvas

    var body: some View {
        GeometryReader { _ in
            ForEach(canvas.strokes) { stroke in
                StrokeView(stroke: stroke)
            }

            ForEach(canvas.images) { image in
                if let uiImage = UIImage(data: image.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .position(image.location)
                }
            }
            if let activeStroke = canvas.activeStroke {
                StrokeView(stroke: activeStroke)
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .gesture(strokeGesture)
    }

    var strokeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                canvas.addPointToActiveStroke(value.location)
            }
            .onEnded { value in
                canvas.addPointToActiveStroke(value.location)
                canvas.finishStroke()
            }
    }
}

struct CanvasView_Previews: PreviewProvider {
    static var previews: some View {
        CanvasView(canvas: Canvas())
            .previewLayout(.sizeThatFits)
    }
}
