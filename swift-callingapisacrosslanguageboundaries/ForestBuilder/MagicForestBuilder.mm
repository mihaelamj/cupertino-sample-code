/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements C++ functions that use the Swift types that create the magic forests.
*/

#include "MagicForestBuilder.hpp"
#include <Forest/Forest.h>
#include <ForestBuilder/ForestBuilder-Swift.h>

Forest * _Nonnull forestBuilder::createEnchantedForest() {
    // Create an instance of Swift's `MagicForest` enum, set to its `enchanted` case.
    auto enchantedForestKind = ForestBuilder::MagicForest::enchanted();
    // Call a Swift method from C++.
    return enchantedForestKind.createForest();
}

Forest * _Nonnull createCustomForest() {
    // Create an instance of Swift's `CustomOneTreeForest` struct.
    auto customForest = ForestBuilder::CustomOneTreeForest::init(/*oakForestName=*/ swift::String("Oak forest"), 5);
    // Create an instance of Swift's `MagicForest` enum, set to its `custom` case.
    auto customForestKind = ForestBuilder::MagicForest::custom(customForest);
    // Call a Swift method from C++.
    return customForestKind.createForest();
}
