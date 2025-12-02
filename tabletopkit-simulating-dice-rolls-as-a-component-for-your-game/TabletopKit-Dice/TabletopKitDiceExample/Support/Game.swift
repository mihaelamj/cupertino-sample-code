/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container to organize classes for the game.
*/
import SwiftUI
import RealityKit
import Spatial
import TabletopKit

@Observable
class Game {
    let tabletopGame: TabletopGame
    let root = Entity()
    let tableBounds: BoundingBox
    
    var lastRollScore: Int = 0
        
    @MainActor
    init() {
        root.name = "Game root"
        
        let tabletop = RoundTabletop()
        tableBounds = tabletop.entity.visualBounds(relativeTo: nil)
        
        var setup = TableSetup(tabletop: tabletop)
        setup.add(seat: PlayerSeat(index: 0, position: .init(x: 0, z: +0.5), rotation: .init(degrees: 0)))
        setup.add(equipment: tetrahedronDie(index: 1))
        setup.add(equipment: cubeDie(index: 2))
        setup.add(equipment: octahedronDie(index: 3))
        setup.add(equipment: customOctahedronDie(index: 4))
        setup.add(equipment: decahedronDie(index: 5))
        setup.add(equipment: dodecahedronDie(index: 6))
        setup.add(equipment: icosahedronDie(index: 7))
        
        tabletopGame = TabletopGame(tableSetup: setup)
        
        // Ensure that the player is seated so they can interact with the game.
        tabletopGame.claimAnySeat()
    }
    
    func repositionTable(content: RealityViewContent, proxy: GeometryProxy3D) {
        // The 'root' entity is direct child of the scene so the sample
        // can frame in scene space
        let frame = content.convert(proxy.frame(in: .global), from: .global, to: .scene)
        
        root.transform.translation = .init(x: 0,
                                           // Make sure the table is at the bottom of the volume.
                                           y: frame.min.y,
                                           // Make sure the closest edge of the table is
                                           // against the front edge of the volume.
                                           z: -tableBounds.min.z)
    }
    
    func updateLastRollScore(for tossedDice: [Die]) {
        tabletopGame.withCurrentSnapshot { snapshot in
            var score = 0
            for die in tossedDice {
                score += die.calculateScore(for: snapshot.state(for: die))
            }
            lastRollScore = score
        }
    }
}
