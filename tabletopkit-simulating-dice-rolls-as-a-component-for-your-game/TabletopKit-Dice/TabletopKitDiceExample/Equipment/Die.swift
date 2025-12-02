/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that represents a die and functions for different dice types.
*/
import SwiftUI
import RealityKit
import TabletopKit
import RealityKitContent

extension EquipmentIdentifier {
    static var tableID: Self { .init(0) }
    static func handID(_ index: Int) -> Self { .init(100 + index) }
    static func diceID(_ index: Int) -> Self { .init(1000 + index) }
}

class Die: EntityEquipment {
    let entity: Entity
    let id: EquipmentIdentifier
    let initialState: RawValueState
    
    let tossableRepresentation: TossableRepresentation
    let faceType: any TossableRepresentation.TossableFace.Type
    let faceMap: any TossableFaceMap

    init(index: Int,
         entityName: String,
         representation: TossableRepresentation,
         faceMap: any TossableFaceMap) {
        
        // Calculate the layout in the base class because it's consistent
        // across all dice types.
        let spacing: Double = 0.06
        let startX: Double = -0.15
        
        // Initialize the start position of the die in a line across the center
        // with even spacing.
        let initialPose: TableVisualState.Pose2D = .init(position: .init(x: startX + Double(index) * spacing, z: 0),
                                                         rotation: .zero)
        let initialFace = representation.face(for: .identity)

        entity = try! ModelEntity.load(named: entityName, in: realityKitContentBundle)
        addShadowRecursive(entity: entity)

        id = .diceID(index)
        initialState = .init(rawValue: initialFace.rawValue, parentID: .tableID, pose: initialPose, entity: entity)
        tossableRepresentation = representation
        faceType = type(of: initialFace)
        self.faceMap = faceMap
    }

    func restingOrientation(state: RawValueState) -> Rotation3D {
        // Get the face that corresponds to the given state of the equipment.
        guard let currentFace = faceType.init(rawValue: state.rawValue) else {
            fatalError("The rawValue in the state was set with an invalid value.")
        }
        
        // Return the resting orientation that corresponds to the face.
        return currentFace.restingOrientation
    }
    
    func calculateScore(for state: RawValueState) -> Int {
        // Get the face that corresponds to the given state of the equipment.
        guard let currentFace = faceType.init(rawValue: state.rawValue) else {
            fatalError("The rawValue in the state was set with an invalid value")
        }
        
        // Determine the score that corresponds to the face and return it.
        guard let score = faceMap.value(for: currentFace) else {
            fatalError("The wrong face map was used when initializing this die")
        }
        return score
    }
    
    func faceWithHighestScore() -> any TossableRepresentation.TossableFace {
        guard let maxValue = faceMap.values.max() else {
            fatalError("The face map is empty")
        }
        
        guard let face = faceMap.face(for: maxValue) else {
            fatalError("There is a bug in the face map, returning values that have no face")
        }
        
        return face
    }
}

// MARK: - Dice Types

func tetrahedronDie(index: Int, height: Float = 0.02) -> Die {
    Die(index: index,
        entityName: "dice/D4",
        representation: TossableRepresentation.tetrahedron(height: height),
        faceMap: tetrahedronFaceMap)
}

func cubeDie(index: Int, height: Float = 0.02) -> Die {
    Die(index: index,
        entityName: "dice/D6",
        representation: TossableRepresentation.cube(height: height),
        faceMap: cubeFaceMap)
}

func octahedronDie(index: Int, height: Float = 0.02) -> Die {
    Die(index: index,
        entityName: "dice/D8",
        representation: TossableRepresentation.octahedron(height: height),
        faceMap: octahedronFaceMap)
}

func customOctahedronDie(index: Int, height: Float = 0.02) -> Die {
    Die(index: index,
        entityName: "dice/D8_customFaces",
        representation: TossableRepresentation.octahedron(height: height),
        faceMap: customOctahedronFaceMap)
}

func decahedronDie(index: Int, height: Float = 0.02) -> Die {
    Die(index: index,
        entityName: "dice/D10",
        representation: TossableRepresentation.decahedron(height: height),
        faceMap: decahedronFaceMap)
}

func dodecahedronDie(index: Int, height: Float = 0.02) -> Die {
    Die(index: index,
        entityName: "dice/D12",
        representation: TossableRepresentation.dodecahedron(height: height),
        faceMap: dodecahedronFaceMap)
}

func icosahedronDie(index: Int, height: Float = 0.02) -> Die {
    Die(index: index,
        entityName: "dice/D20",
        representation: TossableRepresentation.icosahedron(height: height),
        faceMap: icosahedronFaceMap)
}
