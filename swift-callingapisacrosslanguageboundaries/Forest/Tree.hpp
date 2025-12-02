/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The C++ tree class.
*/

#pragma once

#include <swift/bridging>
#include <string>
#include <cassert>

enum class TreeKind {
    Redwood,
    Oak,
    Palm
};

class Forest;

class Tree {
public:
    struct Branch {
        int length;
    };
    
    constexpr static size_t MaxTreeBranches = 10;

    Tree(TreeKind kind, std::string name);

    // Allows Swift to access this as a `.kind` property.
    inline TreeKind getKind() const SWIFT_COMPUTED_PROPERTY {
        return kind;
    }

    // Allows Swift to access this as a `.name` property.
    std::string getName() const SWIFT_COMPUTED_PROPERTY {
        return name;
    }

    // These `begin` and `end` methods that iterate over the branches allow `Tree` to conform to Swift's `Sequence` protocol.
    // In particular, this allows Swift to regard a tree as a collection of branches.
    const Branch * _Nonnull begin() const {
        return branches;
    }
    const Branch * _Nonnull end() const {
        return branches + numBranches;
    }

    // Allows Swift to access this as a `.numBranches` property.
    size_t getNumBranches() const SWIFT_COMPUTED_PROPERTY {
        return numBranches;
    }

    Branch &getLongestBranch();

    const Branch &getLongestBranch() const;

private:
    TreeKind kind;
    std::string name;
    size_t numBranches = 0;
    Branch branches[MaxTreeBranches];
};
