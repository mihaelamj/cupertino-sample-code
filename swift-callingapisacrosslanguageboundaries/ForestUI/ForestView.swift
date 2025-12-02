/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements a SwiftUI view that presents a C++ forest type.
*/

import Forest
import SwiftUI

public struct ForestView: View {
    let forest: Forest

    public init(forest: Forest) {
        self.forest = forest
    }

    public var body: some View {
        HStack {
            Text("✨")
            Text(String(forest.forestName))
            Text("✨")
        }.padding(2.0)
        VStack {
            ForEach(forest.trees, id: \.name) { tree in
                HStack {
                    Text(tree.emoji)
                    Text(String(tree.name))
                    Text("(\(tree.branchLengthDescription))")
                    Text("(longest branch = \(tree.longestBranchLength))")
                }.padding(2.0)
            }
        }
    }
}

// This is an extension on the C++ type `Forest`.
extension Forest {
    // A Swift array of C++ `Tree` values in the forest.
    var trees: [Tree] {
        // The `getTrees` method is unsafe, as it returns a C++ reference.
        // Use it safely by following these two guidelines:
        // - Convert the C++ reference to a Swift
        //   array immediately.
        // - Call `withExtendedLifetime` on `self` to prevent releasing the
        //   `Forest` instance before you convert the C++ vector in the
        //   `Forest` to an array.
        let result = Array(__getTreesUnsafe().pointee)
        withExtendedLifetime(self) {}
        return result
    }
}
