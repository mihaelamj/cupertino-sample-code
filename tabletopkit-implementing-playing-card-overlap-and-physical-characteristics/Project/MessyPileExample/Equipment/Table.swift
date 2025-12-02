/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a table.
*/

import TabletopKit
import RealityKit
import RealityKitContent

extension EquipmentIdentifier {
    static var tableID: Self { .init(0) }
    static var messyPileId: Self { .init(1) }
    static var stackPileId: Self { .init(2) }
}

struct Table: EntityTabletop {
    var entity: Entity
    var id: EquipmentIdentifier { .tableID }
    var shape: TabletopShape { .round(entity: entity) }
    
    init() {
        entity = try! Entity.load(named: "table", in: realityKitContentBundle)
        entity.scale *= 100
    }
}
