/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The C++ class that contains a collection of trees.
*/

#pragma once

#include <Forest/IntrusiveRefCounted.hpp>
#include <Forest/Tree.hpp>
#include <swift/bridging>
#include <vector>

class Forest : public IntrusiveRefCounted<Forest> {
public:
    // Using `SWIFT_COMPUTED_PROPERTY` allows Swift to access this as a `.forestName` property.
    const std::string getForestName() SWIFT_COMPUTED_PROPERTY {
        return name;
    }

    inline std::vector<Tree> &getTrees() {
        return trees;
    }

    void addTree(const Tree &tree);

    static Forest * _Nonnull createForest(std::string name, const std::vector<Tree> &trees);

private:
    int retainCount = 0;
    std::string name;
    std::vector<Tree> trees;
    // Using `SWIFT_SHARED_REFERENCE` allows Swift to import this as a reference-counted reference type.
} SWIFT_SHARED_REFERENCE(forestRetain,forestRelease);

void forestRetain(Forest * _Nonnull forest);

void forestRelease(Forest * _Nonnull forest);

// A specialization of `std::vector` that becomes available as a concrete type in Swift.
using VectorOfTrees = std::vector<Tree>;
