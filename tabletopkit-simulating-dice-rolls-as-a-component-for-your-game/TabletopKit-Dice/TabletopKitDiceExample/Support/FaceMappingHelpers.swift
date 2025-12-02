/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A definition of every equipment type that the app uses.
*/

import TabletopKit

// A helper structure that represents a 1-1 mapping between faces of a specific
// type to score, like TetrahedronFace.
//
// The correspondence between logical faces and scores is arbitrary and depends
// on the game.
//
// Different dice with the same geometric shape could have different mappings
// because they can have different values on their faces. For example, see
// `octahedronFaceMap` and `customOctahedronFaceMap` below.
struct FaceMap<FaceType: Hashable & TossableRepresentation.TossableFace>: TossableFaceMap, ExpressibleByDictionaryLiteral {
    
    private let faceToValue: [FaceType: Int]
    private let valueToFace: [Int: FaceType]

    init(dictionaryLiteral elements: (FaceType, Int)...) {
        self.faceToValue = Dictionary(uniqueKeysWithValues: elements)
        self.valueToFace = Dictionary(uniqueKeysWithValues: elements.map { ($1, $0) })
    }

    func value(for face: any TossableRepresentation.TossableFace) -> Int? {
        guard let face = face as? FaceType else {
            return nil
        }
        return faceToValue[face]
    }
    
    func face(for value: Int) -> (any TossableRepresentation.TossableFace)? {
        valueToFace[value]
    }
    
    var values: Set<Int> { Set(valueToFace.keys) }
}

// A protocol that helps store mappings regardless of the actual face type.
protocol TossableFaceMap {
    func value(for face: any TossableRepresentation.TossableFace) -> Int?
    func face(for value: Int) -> (any TossableRepresentation.TossableFace)?
    var values: Set<Int> { get }
}

// MARK: - Dice Mappings

// The dice mappings that the game uses.
//
// The assets in the sample are made to match the order of the faces in the enum,
// using standard die face positioning, so the mapping is trivial. However,
// `D8_customFaces` has some more arbitrary face values.
//
// Other games might have more interesting mappings, for example:
// - different order of the faces
// - non-standard faces (D4 with faces 10, 20, 42, 1000, or "dragon face", "firework face" etc)

let tetrahedronFaceMap: FaceMap<TossableRepresentation.TetrahedronFace> = [
    .a: 1,
    .b: 2,
    .c: 3,
    .d: 4
]

let cubeFaceMap: FaceMap<TossableRepresentation.CubeFace> = [
    .a: 1,
    .b: 2,
    .c: 3,
    .d: 4,
    .e: 5,
    .f: 6
]

let octahedronFaceMap: FaceMap<TossableRepresentation.OctahedronFace> = [
    .a: 1,
    .b: 2,
    .c: 3,
    .d: 4,
    .e: 5,
    .f: 6,
    .g: 7,
    .h: 8
]

// The sample associates this mapping with `D8_customFaces` to shows a more
// arbitrary mapping.
let customOctahedronFaceMap: FaceMap<TossableRepresentation.OctahedronFace> = [
    .a: 1,
    .b: 5,
    .c: 10,
    .d: 15,
    .e: 20,
    .f: 25,
    .g: 30,
    .h: 35
]

let decahedronFaceMap: FaceMap<TossableRepresentation.DecahedronFace> = [
    .a: 1,
    .b: 2,
    .c: 3,
    .d: 4,
    .e: 5,
    .f: 6,
    .g: 7,
    .h: 8,
    .i: 9,
    .j: 10
]

let dodecahedronFaceMap: FaceMap<TossableRepresentation.DodecahedronFace> = [
    .a: 1,
    .b: 2,
    .c: 3,
    .d: 4,
    .e: 5,
    .f: 6,
    .g: 7,
    .h: 8,
    .i: 9,
    .j: 10,
    .k: 11,
    .l: 12
]

let icosahedronFaceMap: FaceMap<TossableRepresentation.IcosahedronFace> = [
    .a: 1,
    .b: 2,
    .c: 3,
    .d: 4,
    .e: 5,
    .f: 6,
    .g: 7,
    .h: 8,
    .i: 9,
    .j: 10,
    .k: 11,
    .l: 12,
    .m: 13,
    .n: 14,
    .o: 15,
    .p: 16,
    .q: 17,
    .r: 18,
    .s: 19,
    .t: 20
]
