/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The function that creates the enchanted forest that the app displays.
*/

import Forest
import ForestBuilder

func createEnchantedForest() -> Forest {
    // Create an enchanted forest using a call to the C++ function that creates it, using the Swift API in `ForestBuilder`.
    let result = forestBuilder.createEnchantedForest()

    // Add another tree to the forest.
    result.addTree(Tree(TreeKind.Redwood, "Johny"))
    return result
}
