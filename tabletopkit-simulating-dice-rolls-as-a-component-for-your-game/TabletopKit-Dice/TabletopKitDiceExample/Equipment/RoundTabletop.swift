/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a table.
*/

import RealityKit
import TabletopKit
import RealityKitContent

struct RoundTabletop: EntityTabletop {
    var entity: Entity
    var id: EquipmentIdentifier { .tableID }
    var shape: TabletopShape
    
    init() {
        entity = try! Entity.load(named: "table/table", in: realityKitContentBundle)
        shape = .round(entity: entity)
    }
}
