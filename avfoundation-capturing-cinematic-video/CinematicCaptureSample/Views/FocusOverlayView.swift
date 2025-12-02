/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A views that draws focus rectangles over the capture preview.
*/

import Foundation
import SwiftUI
import AVFoundation

struct FocusOverlayView: View {

    @State private var isPressing = false
    @State private var longPressPoint: CGPoint = .zero

    private let camera: Camera

    enum PreviewType {
        case tap
        case longPress
    }

    init(camera: Camera) {
        self.camera = camera
    }

    var body: some View {
        
        GeometryReader { geometry in
            
            ZStack {
                ForEach(camera.metadataManager.cinematicFocusMetadata, id: \.objectID) { cinematicFocusMetadata in
                    rectangle(for: cinematicFocusMetadata, geometry: geometry)
                }
                Rectangle()
                    .fill(.clear)
                    .contentShape(.rect)
                    .onTapGesture { point in
                        preview(at: point.normalized(for: geometry), type: .tap)
                    }
                    .onLongPressGesture(minimumDuration: 0.3) {
                        preview(at: longPressPoint.normalized(for: geometry), type: .longPress)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !isPressing else { return }
                                isPressing = true
                                longPressPoint = value.location
                            }
                            .onEnded { _ in
                                isPressing = false
                            }
                    )
            }
        }
    }

    private func preview(at point: CGPoint, type: PreviewType) {
        Task {
            switch type {
            case .tap:
                await camera.tapPreview(at: point)
            case .longPress:
                await camera.longPressPreview(at: point)
            }
        }
    }

    private func rectangle(for metadata: CinematicFocusMetadata, geometry: GeometryProxy) -> some View {
        
        var color: Color
        var strokeStyle: StrokeStyle

        let denormalizedRect = CGRect(
            x: metadata.layerBoundsNormalized.minX * geometry.size.width,
            y: metadata.layerBoundsNormalized.minY * geometry.size.height,
            width: metadata.layerBoundsNormalized.width * geometry.size.width,
            height: metadata.layerBoundsNormalized.height * geometry.size.height
        )
                
        switch metadata.focusMode {
        case .weak:
            color = .yellow
            strokeStyle = StrokeStyle(lineWidth: 2, dash: [5, 4])
        case .strong:
            color = .yellow
            strokeStyle = StrokeStyle(lineWidth: 2)
        case .none:
            color = .white
            strokeStyle = StrokeStyle(lineWidth: 2)
        @unknown default:
            fatalError()
        }
    
        return Rectangle()
            .stroke(color, style: strokeStyle)
            .contentShape(.rect)
            .frame(
                width: denormalizedRect.width,
                height: denormalizedRect.height
            )
            .position(x: denormalizedRect.midX,
                      y: denormalizedRect.midY)
    }

}

fileprivate extension CGPoint {
    func normalized(for proxy: GeometryProxy) -> CGPoint {
        .init(x: x / proxy.size.width, y: y / proxy.size.height)
    }
}
