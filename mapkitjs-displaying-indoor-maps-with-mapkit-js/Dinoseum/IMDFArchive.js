/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The IMDF archive class contains the indoor mapping data organized by feature types and implements level-based feature filtering.

See LICENSE folder for this sample’s licensing information.
*/
"use strict";

function ImdfArchive(features) {
    this.features = features;
    this.featuresByType = {};
    features.forEach(function(feature) {
        this.featuresByType[feature.feature_type] = this.featuresByType[feature.feature_type] || [];
        this.featuresByType[feature.feature_type].push(feature);
    }, this);
}

ImdfArchive.load = function(callback) {
    var files = ["anchor", "amenity", "level", "unit", "footprint", "opening", "occupant", "venue"];

    var completed = 0;
    var features = [];

    // The IMDF features this sample uses include openings, amenities, anchors, and occupants.
    files.forEach(function(name) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "/Dinoseum/venue/" + name + ".geojson");
        xhr.addEventListener("load", function() {
            completed += 1;
            features = features.concat(JSON.parse(xhr.responseText).features);
            if (completed === files.length) {
                callback(new ImdfArchive(features));
            }
        });
        xhr.send();
    });
}

ImdfArchive.prototype.levels = function(ordinal) {
    // Levels model floors in a building.
    return this.featuresByType["level"].filter(function(feature) {
        return feature.properties.ordinal === ordinal;
    });
}

ImdfArchive.prototype.unitsOnLevel = function(levelId) {
    return this.featuresByType["unit"].filter(function(feature) {
        return feature.properties.level_id === levelId;
    });
}

ImdfArchive.prototype.unitsByIdOnLevel = function(levelId) {
    // Cache the units (such as rooms or walkways) by their ID per level, so this data can be reused.
    this._unitsByIdOnLevelCache = this._unitsByIdOnLevelCache || {};
    if ( !(levelId in this._unitsByIdOnLevelCache) ) {
        var units = {};
        this.featuresByType["unit"].forEach(function(unit) {
            if (unit.properties.level_id === levelId)
                units[unit.id] = unit;
        });
        this._unitsByIdOnLevelCache[levelId] = units;
    }
    return this._unitsByIdOnLevelCache[levelId];
}

// The methods are filters that find the features by floor.
ImdfArchive.prototype.openingsOnLevel = function(levelId) {
    return this.featuresByType["opening"].filter(function(feature) {
        return feature.properties.level_id === levelId;
    });
}

ImdfArchive.prototype.amenitiesOnLevel = function(levelId) {
    var amenities = {};
    var result = [];
    var unitsById = this.unitsByIdOnLevel(levelId);
    this.featuresByType["amenity"].forEach(function(amenity) {
        var unitIdsContainingAmenity = amenity.properties.unit_ids;
        for(var i in unitIdsContainingAmenity) {
            if (unitIdsContainingAmenity[i] in unitsById && !(amenity.id in amenities)) {
                amenities[amenity.id] = true;
                result.push(amenity);
                break;
            }
        }
    });
    return result;
}

ImdfArchive.prototype.anchorByIdOnLevel = function(levelId) {
    var unitsById = this.unitsByIdOnLevel(levelId);
    var result = {};
    this.featuresByType["anchor"].forEach(function(anchor) {
        if (anchor.properties.unit_id in unitsById)
            result[anchor.id] = anchor;
    });
    return result;
}

ImdfArchive.prototype.occupantsWithAnchorsOnLevel = function(levelId) {
    var anchorById = this.anchorByIdOnLevel(levelId);
    var result = [];
    this.featuresByType["occupant"].forEach(function(occupant) {
        if (occupant.properties.anchor_id in anchorById)
            result.push({occupant: occupant, anchor: anchorById[occupant.properties.anchor_id]});
    });
    return result;
}