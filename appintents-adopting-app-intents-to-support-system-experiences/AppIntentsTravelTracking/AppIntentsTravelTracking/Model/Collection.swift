/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model object that represents a collection of landmarks.
*/

import SwiftUI

@Observable
class Collection: Codable, Identifiable {
    var id: Int
    var name: String
    var description: String
    var landmarkIds: [Int]
    var landmarks: [Landmark] = []
    
    var isFavoritesCollection: Bool {
        return id == 1001
    }
    
    enum CodingKeys: String, CodingKey {
        case _id = "id"
        case _name = "name"
        case _description = "description"
        case _landmarkIds = "landmarkIds"
        case _landmarks = "landmarks"
    }
    
    init(id: Int, name: String, description: String, landmarkIds: [Int], landmarks: [Landmark]) {
        self.id = id
        self.name = name
        self.description = description
        self.landmarkIds = landmarkIds
        self.landmarks = landmarks
    }
}

extension Collection: Equatable {
    static func == (lhs: Collection, rhs: Collection) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Collection: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Collection {
    var backgroundColor: some ShapeStyle {
        if (id - 1000) % 4 == 0 {
            return Color.pink.gradient
        }
        
        if (id - 1000) % 3 == 0 {
            return Color.orange.gradient
        }
        
        if (id - 1000) % 2 == 0 {
            return Color.purple.gradient
        }

        return Color.teal.gradient
    }
}

extension Collection {
    @ViewBuilder func imageForListItem() -> some View {
        switch landmarks.count {
        case 1...3:
            Image(landmarks[0].thumbnailImageName)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
        case 4, 4...:
            let firstLandmark = landmarks[0]
            let secondLandmark = landmarks[1]
            let thirdLandmark = landmarks[2]
            let fourthLandmark = landmarks[3]
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    Image(firstLandmark.thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                    Image(secondLandmark.thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                }
                GridRow {
                    Image(thirdLandmark.thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                    Image(fourthLandmark.thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                }
            }
            .cornerRadius(Constants.collectionGridItemCornerRadius)
        default:
            RoundedRectangle(cornerRadius: 8.0)
                .fill(backgroundColor)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    GeometryReader { geometry in
                        Image(systemName: "square.grid.2x2.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                            .offset(x: geometry.size.width / 4, y: geometry.size.height / 4)
                            .foregroundColor(.white)
                    }
                }
        }
    }
}

extension Collection {
    subscript(contains landmark: Landmark) -> Bool {
        get {
            landmarks.contains(landmark)
        }
        set {
            if newValue, !landmarks.contains(landmark) {
                landmarks.append(landmark)
            } else if !newValue {
                landmarks.removeAll { $0.id == landmark.id }
            }
        }
    }
}
