/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A declaration of every equipment type that the game uses.
*/
import Foundation
import UIKit
import Spatial
import RealityKit
import TabletopKit
import RealityKitContent

let stoneCount = 26
let lilyPadCount = 11
let logCount = 9
let coinCount = 24

extension EquipmentIdentifier {
    static var tableID: Self { .init(0) }
    
    // Convenience functions to generate each unique `EquipmentIdentifier` for the equipment.
    static func playerID(for seat: Int) -> Self { .init(100 + seat) }
    static func aimingSightID(for seat: Int) -> Self { .init(200 + seat) }
    static func bankID(for seat: Int) -> Self { .init(300 + seat) }
    static func stoneID(for index: Int) -> Self { .init(1000 + index) }
    static func lilyPadID(for index: Int) -> Self { .init(2000 + index) }
    static func logID(for index: Int) -> Self { .init(3000 + index) }
    static func coinID(for index: Int) -> Self { .init(4000 + index) }
}

extension [EquipmentIdentifier] {
    static var allStones: Self { (0..<stoneCount).map { .stoneID(for: $0) } }
    static var allLilyPads: Self { (0..<lilyPadCount).map { .lilyPadID(for: $0) } }
    static var allLogs: Self { (0..<logCount).map { .logID(for: $0) } }
}

let seatOffset = 2.0
let playerStartLocationOffset = 0.85
let playerStatOffset = 0.2

struct PlayerSeat: TableSeat {
    let id: ID
    var initialState: TableSeatState

    // Four seats around the edges of the table, each facing the center.
    static let seatPoses: [TableVisualState.Pose2D] = [
        .init(position: .init(x: 0, z: seatOffset), rotation: .degrees(0)),
        .init(position: .init(x: seatOffset, z: 0), rotation: .degrees(90)),
        .init(position: .init(x: 0, z: -seatOffset), rotation: .degrees(180)),
        .init(position: .init(x: -seatOffset, z: 0), rotation: .degrees(-90))
    ]
    
    static let playerStartLocationPoses: [TableVisualState.Pose2D] = [
        .init(position: .init(x: 0, z: playerStartLocationOffset), rotation: .degrees(180)),
        .init(position: .init(x: playerStartLocationOffset, z: 0), rotation: .degrees(-90)),
        .init(position: .init(x: 0, z: -playerStartLocationOffset), rotation: .degrees(0)),
        .init(position: .init(x: -playerStartLocationOffset, z: 0), rotation: .degrees(90))
    ]
    
    static let playerStatPositions: [TableVisualState.Point2D] = [
        .init(x: playerStatOffset, z: playerStartLocationOffset),
        .init(x: playerStartLocationOffset, z: playerStatOffset),
        .init(x: -playerStatOffset, z: -playerStartLocationOffset),
        .init(x: -playerStartLocationOffset, z: -playerStatOffset)
    ]

    init(id: TableSeatIdentifier, pose: TableVisualState.Pose2D) {
        self.id = id
        let spatialSeatPose: TableVisualState.Pose2D = .init(position: pose.position,
                                                             rotation: pose.rotation)
        initialState = .init(pose: spatialSeatPose)
    }
}

struct Table: Tabletop {
    var entity: Entity
    var id: EquipmentIdentifier
    var shape: TabletopShape
    
    @MainActor
    init(id: EquipmentIdentifier) {
        self.entity = try! Entity.load(named: "LayeredWater", in: realityKitContentBundle)
        self.entity.transform.scale.x = 1.95
        self.entity.transform.scale.z = 1.95
        self.id = id
        shape = .rectangular(entity: entity)
    }
}

// The bank is the starting spot for each player when the game begins.
struct Bank: EntityEquipment {
    typealias State = BaseEquipmentState
    var initialState: State
    var entity: Entity
    var id: EquipmentIdentifier

    @MainActor
    init(id: EquipmentIdentifier, pose: TableVisualState.Pose2D) {
        let mesh = MeshResource.generateBox(width: 0.1,
                                            height: 0.01,
                                            depth: 0.1,
                                            cornerRadius: 0.1)
        
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .brown)
        entity = ModelEntity(mesh: mesh, materials: [mat])
        entity.components.set(GroundingShadowComponent(castsShadow: true, receivesShadow: true))
        
        self.id = id
        initialState = State(parentID: .tableID, seatControl: .restricted([]), pose: pose, entity: entity)
    }
}

// The game piece is the toad ball character, which a player controls.
struct Player: EntityEquipment {
    typealias State = PlayerState
    var initialState: State
    var entity: Entity
    var id: EquipmentIdentifier
    var seat: Int
        
    var pullVisual: Entity
    let maxAimLength = 0.3
    
    var collectAudio: AudioFileResource
    var jumpAudio: AudioFileResource

    @MainActor
    init(id: EquipmentIdentifier, seat: Int, pose: TableVisualState.Pose2D) {
        switch seat {
        case 0:
            entity = try! Entity.load(named: "frogBall_pink", in: realityKitContentBundle)
        case 1:
            entity = try! Entity.load(named: "frogBall_yellow", in: realityKitContentBundle)
        case 2:
            entity = try! Entity.load(named: "frogBall_green", in: realityKitContentBundle)
        default:
            entity = try! Entity.load(named: "frogBall_blue", in: realityKitContentBundle)
        }
        
        entity.scale *= 0.8
        
        collectAudio = try! AudioFileResource.load(named: "collect.mp3")
        jumpAudio = try! AudioFileResource.load(named: "jump.m4a")
        
        self.id = id
        self.seat = seat
        initialState = State(base: .init(parentID: .bankID(for: seat),
                                         seatControl: .restricted([TableSeatIdentifier(seat)]),
                                         pose: pose,
                                         entity: entity))
        
        // Add visualizations of pull direction and strength.
        let visualMesh = MeshResource.generateCone(height: 1, radius: 0.005)
        pullVisual = ModelEntity(mesh: visualMesh, materials: [UnlitMaterial(color: .red)])
        entity.addChild(pullVisual)

        hideAimingVisuals()
    }
    
    @MainActor
    func updateAimingVisuals(dragPosition: TableVisualState.Point2D, root: Entity) {
        let playerPosition = entity.position(relativeTo: root)
        var dragVector = Vector3D(x: Double(playerPosition.x) - dragPosition.x, y: 0, z: Double(playerPosition.z) - dragPosition.z)
        dragVector.uniformlyScale(by: min(dragVector.length, maxAimLength) / dragVector.length)
        let scale = SIMD3<Float>(1, Float(dragVector.length), 1)
        pullVisual.setScale(scale, relativeTo: root)
        
        let yawAngle = Float(atan2(-dragVector.x, -dragVector.z))
        let orientation = simd_quatf(angle: yawAngle, axis: .init(x: 0, y: 1, z: 0)) * simd_quatf(angle: .pi / 2, axis: .init(x: -1, y: 0, z: 0))
        pullVisual.setOrientation(orientation, relativeTo: root)
        
        let pullPosition = SIMD3<Float>(
            playerPosition.x - Float(dragVector.x) / 2,
            pullVisual.position(relativeTo: root).y,
            playerPosition.z - Float(dragVector.z) / 2
        )
        pullVisual.setPosition(pullPosition, relativeTo: root)
    }
    
    @MainActor
    func hideAimingVisuals() {
        pullVisual.setScale(.zero, relativeTo: nil)
    }
    
    @MainActor
    func calcTargetPose(dragPosition: TableVisualState.Point2D, root: Entity) -> Pose3D {
        let playerPosition = entity.position(relativeTo: root)
        var dragVector = Vector3D(x: Double(playerPosition.x) - dragPosition.x, y: 0, z: Double(playerPosition.z) - dragPosition.z)
        dragVector.uniformlyScale(by: min(dragVector.length, maxAimLength) / dragVector.length)
        
        let yawAngle = Float(atan2(dragVector.x, dragVector.z))
        let orientation = simd_quatf(angle: yawAngle, axis: .init(x: 0, y: 1, z: 0))
        
        return Pose3D(
            position: simd_float3(playerPosition.x + Float(dragVector.x), 0, playerPosition.z + Float(dragVector.z)),
            rotation: orientation
        )
    }
    
    @MainActor
    func playJumpAudio() {
        entity.playAudio(jumpAudio)
    }
    
    @MainActor
    func playCollectAudio() {
        entity.playAudio(collectAudio)
    }
}

// The aiming sight to use for the pull-and-release motion.
struct AimingSight: Equipment {
    typealias State = BaseEquipmentState
    var initialState: State
    var id: EquipmentIdentifier

    init(id: EquipmentIdentifier, seat: Int) {
        self.id = id
        initialState = State(parentID: .playerID(for: seat), seatControl: .restricted([TableSeatIdentifier(seat)]))
    }
}

// The stone is a static object the players can land on.
struct Stone: EntityEquipment {
    typealias State = BaseEquipmentState
    var initialState: State
    var entity: Entity
    var id: EquipmentIdentifier

    @MainActor
    init(id: EquipmentIdentifier, pose: TableVisualState.Pose2D) {
        entity = try! Entity.load(named: "rock_07", in: realityKitContentBundle)
        entity.scale *= 0.45
        
        self.id = id
        initialState = State(parentID: .tableID, seatControl: .restricted([]), pose: pose, entity: entity)
    }
}

// The lily pad is also an object that players can land on, and slowly sinks when a player stands on it.
struct LilyPad: EntityEquipment {
    typealias State = LilyPadState
    var initialState: State
    var entity: Entity
    var id: EquipmentIdentifier

    @MainActor
    init(id: EquipmentIdentifier, pose: TableVisualState.Pose2D, variation: Int = 0) {
        switch variation {
        case 0:
            entity = try! Entity.load(named: "lily_pad01", in: realityKitContentBundle)
        case 1:
            entity = try! Entity.load(named: "lily_pad02", in: realityKitContentBundle)
        default:
            entity = try! Entity.load(named: "lily_pad03", in: realityKitContentBundle)
        }

        entity.transform.scale *= 1.75
        
        // Disable the hover effect.
        let boundingBox = entity.visualBounds(relativeTo: entity)
        let shape = ShapeResource.generateBox(size: boundingBox.extents).offsetBy(translation: boundingBox.center)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(HoverEffectComponent(.spotlight(.init(strength: 0))))
        
        self.id = id
        initialState = State(base: .init(parentID: .tableID, seatControl: .any, pose: pose, entity: entity))
        
        addAnimation()
    }
    
    @MainActor
    func addAnimation() {
        let lilyIndex = id.rawValue - 2000
        // Remap the unique ID to the range [0, 2pi] so each lily pad starts at a different position.
        let uniqueOffsetAngle = (Float(lilyIndex)) * (2 * Float.pi) / (11)
        
        // Add an animation for the lily pad to float around a center point.
        var orbitStartTransform = entity.transform
        orbitStartTransform.translation.x += cos(uniqueOffsetAngle) * 0.01
        orbitStartTransform.translation.y += sin(uniqueOffsetAngle) * 0.01
        let orbitAnim = OrbitAnimation(
            name: "orbit",
            duration: 6,
            axis: [0, 1, 0],
            startTransform: orbitStartTransform,
            spinClockwise: (id.rawValue % 2 == 0),
            orientToPath: false,
            rotationCount: 1,
            bindTarget: .transform,
        )
        let orbitAnimResource = try! AnimationResource.generate(with: orbitAnim)
        entity.playAnimation(orbitAnimResource.repeat(duration: .infinity), transitionDuration: 0, startsPaused: false)
        
        // Add an animation for the lily pad to slowly rotate around its center.
        var rotationStartTransform = entity.transform
        rotationStartTransform.rotation = rotationStartTransform.rotation * .init(angle: uniqueOffsetAngle, axis: [0, 1, 0])
        let rotationAnim = OrbitAnimation(
            name: "orbit",
            duration: 60,
            axis: [0, 1, 0],
            startTransform: rotationStartTransform,
            spinClockwise: (id.rawValue % 2 == 0),
            orientToPath: true,
            rotationCount: 1,
            bindTarget: .transform,
        )
        let rotationAnimResource = try! AnimationResource.generate(with: rotationAnim)
        entity.playAnimation(rotationAnimResource.repeat(duration: .infinity), transitionDuration: 0, startsPaused: false)
    }
}

// The log is a moving object the players can land on.
struct Log: EntityEquipment {
    typealias State = BaseEquipmentState
    var initialState: State
    var entity: Entity
    var id: EquipmentIdentifier
    
    struct MovementParams {
        let topLeft: TableVisualState.Point2D
        let bottomRight: TableVisualState.Point2D
        let cornerRadius: Double
        let clockwise: Bool
    }
    
    let movementParams: MovementParams
    
    @MainActor
    init(id: EquipmentIdentifier, pose: TableVisualState.Pose2D, movementParams: MovementParams) {
        entity = try! ModelEntity.load(named: "log", in: realityKitContentBundle)
        entity.scale *= 1.2
        
        // Disable the hover effects.
        let boundingBox = entity.visualBounds(relativeTo: entity)
        let shape = ShapeResource.generateBox(size: boundingBox.extents).offsetBy(translation: boundingBox.center)
        entity.components.set(CollisionComponent(shapes: [shape]))
        entity.components.set(HoverEffectComponent(.spotlight(.init(strength: 0))))
        
        self.id = id
        
        // Allow only seat 0 to start programmatic interactions.
        initialState = State(parentID: .tableID, seatControl: .restricted([TableSeatIdentifier(0)]), pose: pose, entity: entity)
        self.movementParams = movementParams
    }
}

// The coin is a collectible token that's available on stones, lily pads, and logs.
struct Coin: EntityEquipment {
    typealias State = CoinState
    var initialState: State
    var entity: Entity
    var id: EquipmentIdentifier

    @MainActor
    init(id: EquipmentIdentifier, parentID: EquipmentIdentifier) {
        entity = try! ModelEntity.load(named: "coin", in: realityKitContentBundle)
        
        self.id = id
        initialState = State(base: .init(parentID: parentID,
                                         seatControl: .restricted([]),
                                         pose: .init(position: .zero, rotation: .degrees(45)),
                                         entity: entity))
        initialState.boundingBox.size.height = 0
        
        let orbit = OrbitAnimation(
            name: "orbit",
            duration: 6,
            axis: [0, 1, 0],
            startTransform: entity.transform,
            spinClockwise: true,
            orientToPath: true,
            rotationCount: 1,
            bindTarget: .transform,
            repeatMode: .repeat
        )
    
        let resource = try! AnimationResource.generate(with: orbit)
    
        entity.playAnimation(resource.repeat(duration: .infinity), transitionDuration: 0, startsPaused: false)
    }
    
    @MainActor
    func collect() {
        entity.isEnabled = false
    }
    
    @MainActor
    func reset() {
        entity.isEnabled = true
    }
}
