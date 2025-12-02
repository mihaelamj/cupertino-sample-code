/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher parameters file.
*/

import Foundation
import AudioToolbox

public protocol NodeSpec {}


extension NodeSpec {
    static func validateID(_ name: String) -> String {
        let msg = "Parameter identifier should: not be empty, begin with a letter, and only contain alphanumeric characters or underscores. Hint: Use camelCase."
        assert(name.isAlphanumeric(), msg)
        return name
    }
}

@resultBuilder struct ParameterGroupBuilder {
    static func buildBlock() -> [NodeSpec] { [] }
    static func buildBlock(_ nodes: NodeSpec...) -> [NodeSpec] { nodes }
}

/// The specification for a group of parameters.
public struct ParameterGroupSpec: NodeSpec {
    let identifier: String
    let name: String
    let children: [NodeSpec]

    init(identifier: String, name: String, @ParameterGroupBuilder _ children: () -> [NodeSpec]) {
        self.identifier = ParameterGroupSpec.validateID(identifier)
        self.name = name
        self.children = children()
    }
}

public struct ParameterTreeSpec: NodeSpec {
    let children: [NodeSpec]
    init(@ParameterGroupBuilder _ children: () -> [NodeSpec]) { self.children = children() }
}

/// `ParameterSpec` mirrors what passes to
/// `AUParameterTree.createParameter`, but also provides a default value.
public struct ParameterSpec: NodeSpec {
    let identifier: String
    let name: String
    let address: AUParameterAddress
    let minValue: AUValue
    let maxValue: AUValue
    let defaultValue: AUValue
    let units: AudioUnitParameterUnit
    let unitName: String?
    let flags: AudioUnitParameterOptions
    let valueStrings: [String]?
    let dependentParameters: [NSNumber]?

    /// Initialize a new parameter spec.
    /// - Parameters:
    ///   - address: A unique `AUParameterAddress` (integer) that represents the parameter.
    ///   - identifier: A unique `String` for accessing the parameter.
    ///   - name: The localized display name of the parameter.
    ///   - units: The parameter's unit of measure.
    ///   - valueRange: The parameter's range in the above units.
    ///   - defaultValue: The default value of the parameter.
    ///   - unitName: The name of the units of measure.
    ///   - flags: A set of the parameter's options.
    ///   - valueStrings: A string representation of each value.
    ///   - dependentParameters: The addresses of dependent parameters.
    init(
        address: AUParameterAddress,
        identifier: String,
        name: String,
        units: AudioUnitParameterUnit,
        valueRange: ClosedRange<AUValue>,
        defaultValue: AUValue,
        unitName: String? = nil,
        flags: AudioUnitParameterOptions = [AudioUnitParameterOptions.flag_IsWritable, AudioUnitParameterOptions.flag_IsReadable],
        valueStrings: [String]? = nil,
        dependentParameters: [NSNumber]? = nil
    ) {
        self.identifier = ParameterSpec.validateID(identifier)
        self.name = name
        self.address = address
        self.minValue = valueRange.lowerBound
        self.maxValue = valueRange.upperBound
        self.defaultValue = defaultValue
        self.units = units
        self.unitName = unitName
        self.flags = flags
        self.valueStrings = valueStrings
        self.dependentParameters = dependentParameters
    }
}

// MARK: - Tree factory for parameter spec

extension AUParameterTree {

    class func createNode(from spec: NodeSpec) -> AUParameterNode {
        switch spec {
        case let parameterSpec as ParameterSpec:
            return AUParameterTree.createParameter(from: parameterSpec)
        case let groupSpec as ParameterGroupSpec:
            return AUParameterTree.createParameterGroup(from: groupSpec)
        default:
            return AUParameterNode()
        }
    }

    class func createParameterGroup(from spec: ParameterGroupSpec) -> AUParameterGroup {
        return self.createGroup(
            withIdentifier: spec.identifier,
            name: spec.name,
            children: spec.children.createAUParameterNodes()
        )
    }

    class func createParameter(from spec: ParameterSpec) -> AUParameter {
        let param = self.createParameter(
            withIdentifier: spec.identifier,
            name: spec.name,
            address: spec.address,
            min: spec.minValue,
            max: spec.maxValue,
            unit: spec.units,
            unitName: spec.unitName,
            flags: spec.flags,
            valueStrings: spec.valueStrings,
            dependentParameters: spec.dependentParameters
        )
        param.value = spec.defaultValue
        return param
    }
}

extension Array where Element == NodeSpec {
    func createAUParameterNodes() -> [AUParameterNode] {
        self.map { spec in
            AUParameterTree.createNode(from: spec)
        }
    }

    func createAUParameterTree() -> AUParameterTree {
        AUParameterTree.createTree(withChildren: self.createAUParameterNodes())
    }
}

extension ParameterTreeSpec {
    func createAUParameterTree() -> AUParameterTree {
        AUParameterTree.createTree(withChildren: self.children.createAUParameterNodes())
    }
}
