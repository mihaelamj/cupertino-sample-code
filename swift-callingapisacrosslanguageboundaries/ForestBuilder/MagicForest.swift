/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Swift types that create custom forests.
*/

import Forest

public struct CustomOneTreeForest {
    let name: String
    let numTrees: Int
    let kind: TreeKind

    public init(oakForestName name: String, numTrees: Int) {
        self.name = name
        self.numTrees = numTrees
        kind = TreeKind.Oak
    }
}

public enum MagicForest {
    case enchanted
    case mythical
    case custom(CustomOneTreeForest)

    public func createForest() -> Forest {
        var trees = VectorOfTrees()
        trees.push_back(Tree(TreeKind.Oak, "Jimmy"))
        // It's possible to iterate over a C++ vector, as it conforms to Swift's sequence.
        for tree in trees {
            debugPrint("Added tree \(tree.name)")
        }

        switch self {
        case .enchanted:
            // Create a C++ reference-counted forest.
            let result = Forest.createForest("Enchanted forest", trees)

            // Add another tree to the enchanted forest.
            result.addTree(Tree(TreeKind.Palm, "Sammy"))
            return result
        case .mythical:
            return Forest.createForest("Mythical forest", trees)

        case .custom(let oneTreeForest):
            trees.clear()
            let result = Forest.createForest(std.string(oneTreeForest.name), trees)
            for treeIndex in 0..<oneTreeForest.numTrees {
                result.addTree(Tree(oneTreeForest.kind, std.string("Tree \(treeIndex)")))
            }
            return result
        }
    }
}
