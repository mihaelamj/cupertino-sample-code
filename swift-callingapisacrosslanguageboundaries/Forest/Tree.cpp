/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the C++ tree class.
*/

#include "Tree.hpp"
#include <random>

Tree::Tree(TreeKind kind, std::string name) : kind(kind), name(name) {
    static std::mt19937 mt{};
    std::uniform_int_distribution<size_t> distribution{ 0, MaxTreeBranches };
    numBranches = distribution(mt);
    for (size_t i = 0; i < numBranches; ++i) {
        branches[i].length = int(distribution(mt));
    }
}

Tree::Branch &Tree::getLongestBranch() {
    assert(numBranches > 0);
    Branch *result = const_cast<Branch *>(begin());
    for (const auto *i = begin() + 1; i != end(); ++i) {
        if (i->length > result->length)
            result = const_cast<Branch *>(i);
    }
    return *result;
}
