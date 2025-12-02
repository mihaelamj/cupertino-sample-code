/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
SwiftUI-related extensions to the C++ tree type.
*/

import Forest

// This is an extension on the C++ type `Tree`.
extension Tree {
    var emoji: String {
        // Switching over a C++ enum.
        switch kind {
        case TreeKind.Oak:
            return "🌳"
        case TreeKind.Redwood:
            return "🌲"
        case TreeKind.Palm:
            return "🌴"
        @unknown default:
            fatalError("unknown case")
        }
    }

    var branchLength: Int {
        // It's possible to use Swift collection APIs on `self` here, as `Tree` conforms to Swift's `Sequence` protocol.
        Int(map { $0.length } .reduce(0, +))
    }

    var branchLengthDescription: String {
        if branchLength < 3 {
            return "small"
        }
        if branchLength < 6 {
            return "medium"
        }
        return "large"
    }

    mutating func getLongestBranch() -> Branch {
        // The `getLongestBranch` C++ method is unsafe, as it returns a C++ reference.
        // Use it safely by following these three guidelines:
        // - Call the non-const overload of `getLongestBranch` C++ member function: `__getLongestBranchMutatingUnsafe`.
        // - Call it from inside a `mutating` Swift method.
        // - Dereference the C++ reference immediately and return a copy of the `pointee`.
        //
        // By mutably borrowing `self` for the duration of
        // the call to Swift's `getLongestBranch`, you can safely dereference
        // the C++ reference without letting Swift destroy `self.
        //
        // Note: It's important to call the non-const overload of `getLongestBranch` C++
        // method here, as Swift sees it as a mutating method. Thus `self`
        // is borrowed instead of copied when calling `__getLongestBranchMutatingUnsafe`.
        return __getLongestBranchMutatingUnsafe().pointee
    }

    var longestBranchLength: Int {
        var mutableSelf = self
        return numBranches > 0 ? Int(mutableSelf.getLongestBranch().length) : 0
    }
}

// Conform the `Tree` type to the `CxxRandomAccessCollection` protocol. This conformance
// in turn ensures that `Tree` also conforms to Swift's `RandomAccessCollection` protocol.
extension Tree: CxxRandomAccessCollection {
    public typealias Element = Tree.Branch
    public typealias RawIterator = UnsafePointer<Tree.Branch>
    public typealias Iterator = CxxIterator<Self>
}
