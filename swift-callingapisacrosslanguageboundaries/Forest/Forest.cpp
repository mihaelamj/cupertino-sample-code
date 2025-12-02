/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the C++ forest class.
*/

#include "Forest.hpp"

void Forest::addTree(const Tree &tree) {
    trees.push_back(tree);
}

Forest *Forest::createForest(std::string name, const std::vector<Tree> &trees) {
    auto result = new Forest;
    result->name = name;
    result->trees = trees;
    return result;
}

void forestRetain(Forest *forest) {
    forest->retain();
}

void forestRelease(Forest *forest) {
    forest->release();
}
