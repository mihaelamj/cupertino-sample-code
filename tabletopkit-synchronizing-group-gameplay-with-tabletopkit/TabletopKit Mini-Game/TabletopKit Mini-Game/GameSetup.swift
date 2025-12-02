/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup of the table for the game.
*/
import RealityKit
import Spatial
import SwiftUI
import TabletopKit
import RealityKitContent

@MainActor
class GameSetup {
    // Arrange player seats and equipment around the table.
    var setup: TableSetup

    init() {
        setup = TableSetup(tabletop: Table(id: .tableID))
        addPlayer()
        addGameLayout()
        registerActions()
    }
    
    func addPlayer() {
        // Add four player seats and their equipment.
        /*
         +---------------------------------+
         |              +---+              |
         |              | O |              |
         |              +---+              |
         |                                 |
         |                                 |
         | +---+                     +---+ |
         | | O |                     | O | |
         | +---+                     +---+ |
         |                                 |
         |                                 |
         |              +---+              |
         |              | O |              |
         |              +---+              |
         +---------------------------------+
         */
        for (index, pose) in PlayerSeat.seatPoses.enumerated() {
            let seat = PlayerSeat(id: TableSeatIdentifier(index), pose: pose)
            let bankPose = PlayerSeat.playerStartLocationPoses[index]
            setup.add(seat: seat)
            setup.add(equipment: Bank(id: .bankID(for: index), pose: bankPose))
            setup.add(equipment: Player(id: .playerID(for: index), seat: index, pose: .identity))
            setup.add(equipment: AimingSight(id: .aimingSightID(for: index), seat: index))
        }
    }
    
    func addGameLayout() {
        layoutPartition()
        layoutCenter()
        layoutBottomRight()
        layoutTopLeft()
        layoutBottomLeft()
        layoutTopRight()
    }
    
    func layoutPartition() {
        // Add four stones in front of each player.
        /*
                   +-+
                   +-+
                   +-+
                   +-+
                   +-+
         +-+-+-+-+     +-+-+-+-+
         +-+-+-+-+     +-+-+-+-+
                   +-+
                   +-+
                   +-+
                   +-+
                   +-+
         */
        setup.add(equipment: Stone(id: .stoneID(for: 0), pose: .init(position: .init(x: 0.4, z: 0), rotation: .zero)))
        setup.add(equipment: Stone(id: .stoneID(for: 1), pose: .init(position: .init(x: 0.5, z: 0), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: Stone(id: .stoneID(for: 2), pose: .init(position: .init(x: 0.6, z: 0), rotation: .init(radians: .pi))))
        setup.add(equipment: Stone(id: .stoneID(for: 3), pose: .init(position: .init(x: 0.7, z: 0), rotation: .init(radians: -.pi / 2))))

        setup.add(equipment: Stone(id: .stoneID(for: 4), pose: .init(position: .init(x: -0.4, z: 0), rotation: .zero)))
        setup.add(equipment: Stone(id: .stoneID(for: 5), pose: .init(position: .init(x: -0.5, z: 0), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: Stone(id: .stoneID(for: 6), pose: .init(position: .init(x: -0.6, z: 0), rotation: .init(radians: .pi))))
        setup.add(equipment: Stone(id: .stoneID(for: 7), pose: .init(position: .init(x: -0.7, z: 0), rotation: .init(radians: -.pi / 2))))
        
        setup.add(equipment: Stone(id: .stoneID(for: 8), pose: .init(position: .init(x: 0, z: 0.4), rotation: .zero)))
        setup.add(equipment: Stone(id: .stoneID(for: 9), pose: .init(position: .init(x: 0, z: 0.5), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: Stone(id: .stoneID(for: 10), pose: .init(position: .init(x: 0, z: 0.6), rotation: .init(radians: .pi))))
        setup.add(equipment: Stone(id: .stoneID(for: 11), pose: .init(position: .init(x: 0, z: 0.7), rotation: .init(radians: -.pi / 2))))

        setup.add(equipment: Stone(id: .stoneID(for: 12), pose: .init(position: .init(x: 0, z: -0.4), rotation: .zero)))
        setup.add(equipment: Stone(id: .stoneID(for: 13), pose: .init(position: .init(x: 0, z: -0.5), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: Stone(id: .stoneID(for: 14), pose: .init(position: .init(x: 0, z: -0.6), rotation: .init(radians: .pi))))
        setup.add(equipment: Stone(id: .stoneID(for: 15), pose: .init(position: .init(x: 0, z: -0.7), rotation: .init(radians: -.pi / 2))))

        setup.add(equipment: Coin(id: .coinID(for: 0), parentID: .stoneID(for: 1)))
        setup.add(equipment: Coin(id: .coinID(for: 1), parentID: .stoneID(for: 2)))
        setup.add(equipment: Coin(id: .coinID(for: 2), parentID: .stoneID(for: 5)))
        setup.add(equipment: Coin(id: .coinID(for: 3), parentID: .stoneID(for: 6)))
        setup.add(equipment: Coin(id: .coinID(for: 4), parentID: .stoneID(for: 9)))
        setup.add(equipment: Coin(id: .coinID(for: 5), parentID: .stoneID(for: 10)))
        setup.add(equipment: Coin(id: .coinID(for: 6), parentID: .stoneID(for: 13)))
        setup.add(equipment: Coin(id: .coinID(for: 7), parentID: .stoneID(for: 14)))
    }
    
    func layoutCenter() {
        // At the center, add three lily pads and three moving logs to rotate around them.
        /*
                    +----+
                    +----+
                ___
          +-+  / x \
          | |  \___/ ___
          | |  ___  / x \
          +-+ / x \ \___/
              \___/
                    +----+
                    +----+
         */
        let logParams = Log.MovementParams(topLeft: .init(x: -0.24, z: -0.24),
                                           bottomRight: .init(x: 0.24, z: 0.24),
                                           cornerRadius: 0.08,
                                           clockwise: true)
        
        setup.add(equipment: Log(id: .logID(for: 0),
                                 pose: .init(position: .init(x: 0.16, z: -0.24), rotation: .degrees(0)),
                                 movementParams: logParams))
        setup.add(equipment: Log(id: .logID(for: 1),
                                 pose: .init(position: .init(x: -0.24, z: 0), rotation: .degrees(90)),
                                 movementParams: logParams))
        setup.add(equipment: Log(id: .logID(for: 2),
                                 pose: .init(position: .init(x: 0.16, z: 0.24), rotation: .degrees(180)),
                                 movementParams: logParams))
        
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 0),
                                     pose: .init(position: .init(x: -0.1, z: 0.1), rotation: .init(radians: .pi)),
                                     variation: 0))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 1),
                                     pose: .init(position: .init(x: -0.05, z: -0.1), rotation: .zero),
                                     variation: 1))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 2),
                                     pose: .init(position: .init(x: 0.1, z: 0.05), rotation: .init(radians: -.pi / 2)),
                                     variation: 2))
        
        setup.add(equipment: Coin(id: .coinID(for: 8), parentID: .lilyPadID(for: 0)))
        setup.add(equipment: Coin(id: .coinID(for: 9), parentID: .lilyPadID(for: 1)))
        setup.add(equipment: Coin(id: .coinID(for: 10), parentID: .lilyPadID(for: 2)))
        setup.add(equipment: Coin(id: .coinID(for: 11), parentID: .logID(for: 0)))
        setup.add(equipment: Coin(id: .coinID(for: 12), parentID: .logID(for: 1)))
        setup.add(equipment: Coin(id: .coinID(for: 13), parentID: .logID(for: 2)))
    }
    
    func layoutBottomRight() {
        // Three moving logs rotate around a stone.
        /*
                  +----+
                  +----+
          +-+
          | |   +-+
          | |   +-+
          +-+
                  +----+
                  +----+
         */
        let logParams = Log.MovementParams(topLeft: .init(x: 0.35, z: 0.35),
                                           bottomRight: .init(x: 0.65, z: 0.65),
                                           cornerRadius: 0.05,
                                           clockwise: false)
        
        setup.add(equipment: Log(id: .logID(for: 3),
                                 pose: .init(position: .init(x: 0.6, z: 0.35), rotation: .degrees(0)),
                                 movementParams: logParams))
        setup.add(equipment: Log(id: .logID(for: 4),
                                 pose: .init(position: .init(x: 0.35, z: 0.5), rotation: .degrees(90)),
                                 movementParams: logParams))
        setup.add(equipment: Log(id: .logID(for: 5),
                                 pose: .init(position: .init(x: 0.6, z: 0.65), rotation: .degrees(180)),
                                 movementParams: logParams))
        
        setup.add(equipment: Stone(id: .stoneID(for: 16), pose: .init(position: .init(x: 0.5, z: 0.5), rotation: .zero)))
        setup.add(equipment: Coin(id: .coinID(for: 14), parentID: .stoneID(for: 16)))
    }
    
    func layoutTopLeft() {
        // Similar to `layoutBottomRight()`.
        let logParams = Log.MovementParams(topLeft: .init(x: -0.65, z: -0.65),
                                           bottomRight: .init(x: -0.35, z: -0.35),
                                           cornerRadius: 0.05,
                                           clockwise: false)
        
        setup.add(equipment: Log(id: .logID(for: 6),
                                 pose: .init(position: .init(x: -0.4, z: -0.65), rotation: .degrees(0)),
                                 movementParams: logParams))
        setup.add(equipment: Log(id: .logID(for: 7),
                                 pose: .init(position: .init(x: -0.65, z: -0.5), rotation: .degrees(90)),
                                 movementParams: logParams))
        setup.add(equipment: Log(id: .logID(for: 8),
                                 pose: .init(position: .init(x: -0.4, z: -0.35), rotation: .degrees(180)),
                                 movementParams: logParams))
        
        setup.add(equipment: Stone(id: .stoneID(for: 17), pose: .init(position: .init(x: -0.5, z: -0.5), rotation: .zero)))
        setup.add(equipment: Coin(id: .coinID(for: 15), parentID: .stoneID(for: 17)))
    }
    
    func layoutBottomLeft() {
        // Add some lily pads and stones to the bottom-left section.
        /*
          ___
         / x \  +-+
         \___/  +-+
                ___
          +-+  / x \  +-+
          +-+  \___/  +-+
          ___         ___
         / x \  +-+  / x \
         \___/  +-+  \___/
         
         */
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 3),
                                     pose: .init(position: .init(x: -0.5, z: 0.5), rotation: .zero),
                                     variation: 1))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 4),
                                     pose: .init(position: .init(x: -0.3, z: 0.7), rotation: .init(radians: -.pi / 2))))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 5),
                                     pose: .init(position: .init(x: -0.7, z: 0.3), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 6),
                                     pose: .init(position: .init(x: -0.7, z: 0.7), rotation: .init(radians: .pi)),
                                     variation: 2))
        
        setup.add(equipment: Stone(id: .stoneID(for: 18), pose: .init(position: .init(x: -0.5, z: 0.3), rotation: .zero)))
        setup.add(equipment: Stone(id: .stoneID(for: 19), pose: .init(position: .init(x: -0.3, z: 0.5), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: Stone(id: .stoneID(for: 20), pose: .init(position: .init(x: -0.5, z: 0.7), rotation: .init(radians: .pi))))
        setup.add(equipment: Stone(id: .stoneID(for: 21), pose: .init(position: .init(x: -0.7, z: 0.5), rotation: .init(radians: -.pi / 2))))
        
        setup.add(equipment: Coin(id: .coinID(for: 16), parentID: .lilyPadID(for: 3)))
        setup.add(equipment: Coin(id: .coinID(for: 17), parentID: .lilyPadID(for: 4)))
        setup.add(equipment: Coin(id: .coinID(for: 18), parentID: .lilyPadID(for: 5)))
        setup.add(equipment: Coin(id: .coinID(for: 19), parentID: .lilyPadID(for: 6)))
    }
    
    func layoutTopRight() {
        // Similar to `layoutBottomLeft()`.
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 7),
                                     pose: .init(position: .init(x: 0.5, z: -0.5), rotation: .init(radians: .pi)),
                                     variation: 1))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 8),
                                     pose: .init(position: .init(x: 0.3, z: -0.7), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 9),
                                     pose: .init(position: .init(x: 0.7, z: -0.3), rotation: .init(radians: -.pi / 2))))
        setup.add(equipment: LilyPad(id: .lilyPadID(for: 10),
                                     pose: .init(position: .init(x: 0.7, z: -0.7), rotation: .zero),
                                     variation: 2))
        
        setup.add(equipment: Stone(id: .stoneID(for: 22), pose: .init(position: .init(x: 0.5, z: -0.3), rotation: .zero)))
        setup.add(equipment: Stone(id: .stoneID(for: 23), pose: .init(position: .init(x: 0.3, z: -0.5), rotation: .init(radians: .pi / 2))))
        setup.add(equipment: Stone(id: .stoneID(for: 24), pose: .init(position: .init(x: 0.5, z: -0.7), rotation: .init(radians: .pi))))
        setup.add(equipment: Stone(id: .stoneID(for: 25), pose: .init(position: .init(x: 0.7, z: -0.5), rotation: .init(radians: -.pi / 2))))
        
        setup.add(equipment: Coin(id: .coinID(for: 20), parentID: .lilyPadID(for: 7)))
        setup.add(equipment: Coin(id: .coinID(for: 21), parentID: .lilyPadID(for: 8)))
        setup.add(equipment: Coin(id: .coinID(for: 22), parentID: .lilyPadID(for: 9)))
        setup.add(equipment: Coin(id: .coinID(for: 23), parentID: .lilyPadID(for: 10)))
    }
    
    func registerActions() {
        setup.register(action: ResetPlayer.self)
        setup.register(action: FreezePlayer.self)
        setup.register(action: ActivatePlayer.self)
        setup.register(action: DecrementHealth.self)
        setup.register(action: CollectCoin.self)
        setup.register(action: ResetCoin.self)
        setup.register(action: SinkLilyPad.self)
        setup.register(action: ResetLilyPad.self)
    }
}
