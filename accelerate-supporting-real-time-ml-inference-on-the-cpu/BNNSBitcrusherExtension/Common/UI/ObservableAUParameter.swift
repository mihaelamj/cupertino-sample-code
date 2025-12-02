/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base-class for SwiftUI-capable `AUParameterNodes`.
*/
import SwiftUI
import AudioToolbox

/// The base-class for SwiftUI-capable `AUParameterNodes`.
///
/// This implementation provides a central point `AUParameterGroup` node to build a set of
/// observable subclasses, and also enables you to traverse the parameter tree using `dynamicMemberLookup`
/// and subscript notation (that is, `parameterTree.paramGroup.parameter`).
///
/// This does *not* provide any of Swift's usual type-safety benefits, and may result in fatal errors if the
/// implementation attempts to access the subscript of an `ObservableAUParameter` (which has no subclasses because it's not a group).
@dynamicMemberLookup
class ObservableAUParameterNode {

    /// Create an `ObservableAUParameterNode`.
    ///
    /// This creates the appropriate subclass, depending on the type of the subclass that the system passes in `AUParameterNode`.
    class func create(_ parameterNode: AUParameterNode) -> ObservableAUParameterNode {
        switch parameterNode {
        case let parameter as AUParameter:
            return ObservableAUParameter(parameter)
        case let group as AUParameterGroup:
            return ObservableAUParameterGroup(group)
        default:
            fatalError("Unexpected AUParameterNode subclass")
        }
    }

    subscript<T>(dynamicMember identifier: String) -> T {
        guard let groupSelf = self as? ObservableAUParameterGroup else {
            fatalError("Calling subscript is only supported on ObservableAUParameterGroups, you called it on \(self)")
        }

        guard let node = groupSelf.children[identifier] else {
            if groupSelf.children.isEmpty {
                fatalError("This group has no subclasses")
            }

            let availableChildren = groupSelf.children.keys.joined(separator: "\n")

            print("Parameter Group \(groupSelf) doesn't have a subclass node named \(identifier), did you mean one of: \n \(availableChildren)")
            fatalError()
        }

        guard let subNode = node as? T else {
            fatalError("Parameter node named \(identifier) can't be converted to the requested type")
        }

        return subNode
    }

    subscript(dynamicMember identifier: String) -> ObservableAUParameterNode {
        guard let groupSelf = self as? ObservableAUParameterGroup else {
            fatalError("Calling subscript is only supported on ObservableAUParameterGroups, you called it on \(self)")
        }

        guard let parameter = groupSelf.children[identifier] else {
            if groupSelf.children.isEmpty {
                fatalError("This group has no subclasses")
            }

            let availableChildren = groupSelf.children.keys.joined(separator: "\n")

            print("Parameter Group \(groupSelf) doesn't have a subclass node named \(identifier), did you mean one of: \n \(availableChildren)")
            fatalError()
        }

        return parameter
    }

    private func asParameter() -> ObservableAUParameter {
        guard let parameter = self as? ObservableAUParameter else {
            fatalError("Node isn't a parameter")
        }
        return parameter
    }

    subscript(dynamicMember keyPath: ReferenceWritableKeyPath<ObservableAUParameter, Float>) -> Float {
        get { self.asParameter()[keyPath: keyPath] }
        set { self.asParameter()[keyPath: keyPath] = newValue }
    }
}

/// An observable version of `AUParameterGroup`.
///
/// The primary purpose here is to expose observable versions of the group's subparameters.
///
final class ObservableAUParameterGroup: ObservableAUParameterNode {

    private(set) var children: [String: ObservableAUParameterNode]

    init(_ parameterGroup: AUParameterGroup) {
        children = parameterGroup.children.reduce(
            into: [String: ObservableAUParameterNode]()
        ) { dict, node in
            let observableNode = ObservableAUParameterNode.create(node)
            dict[node.identifier] = observableNode
        }
    }
}

/// An observable version of `AUParameter`.
///
/// You use `ObservableAUParameter` directly in SwiftUI views as an `ObservedObject`,
/// allowing you to expose a binding to the parameter's value, as well as associated parameter data,
/// such as the minimum, maximum, and default values for the parameter.
///
///`ObservableAUParameter` can also manage automation event types by calling
/// `onEditingChanged()` whenever a UI element changes its editing state.
final class ObservableAUParameter: ObservableAUParameterNode, ObservableObject {

    private weak var parameter: AUParameter?
    private var observerToken: AUParameterObserverToken!
    private var editingState: EditingState = .inactive

    let min: AUValue
    let max: AUValue
    let displayName: String
    let defaultValue: AUValue = 0.0
    let unit: AudioUnitParameterUnit

    init(_ parameter: AUParameter) {
        self.parameter = parameter
        self.value = parameter.value
        self.min = parameter.minValue
        self.max = parameter.maxValue
        self.displayName = parameter.displayName
        self.unit = parameter.unit
        super.init()

        /// Use the `parameter.token(byAddingParameterObserver:)` function to monitor for parameter
        /// changes from the host. The only role of this callback is to update the UI if the host changes the value.
        self.observerToken = parameter.token { (_ address: AUParameterAddress, _ auValue: AUValue) in
            guard address == self.parameter?.address else { return }

            DispatchQueue.main.async {
                // Don't update the UI if the user is currently interacting with it.
                guard self.editingState == .inactive else { return }

                self.editingState = .hostUpdate
                self.value = auValue
                self.editingState = .inactive
            }
        }
    }

    @Published var value: AUValue {
        didSet {
            /// If the editing state is `.hostUpdate`, don't propagate this back to the host.
            guard editingState != .hostUpdate else { return }

            let automationEventType = resolveEventType()
            parameter?.setValue(
                value,
                originator: observerToken,
                atHostTime: 0,
                eventType: automationEventType
            )
            print("Parameter was set \(value)")
        }
    }

    /// A callback for UI elements to notify the parameter when the UI editing state changes.
    ///
    /// This is the core mechanism for ensuring correct automation behavior. With native SwiftUI elements like `Slider`,
    /// pass this method directly into the `onEditingChanged:` argument.
    ///
    /// As long as the UI element correctly sets the editing state, the calls from `ObservableAUParameter` to
    /// `AUParameter.setValue` contain the correct automation event type.
    ///
    /// Call `onEditingChanged` with `true` before sending the first value so that the system can send it with a
    /// `.touch` event. Call `onEditingChanged` with a value of `false` to mark the end
    /// of interaction *after* sending the last value because this is how the SwiftUI `Slider` and `Stepper` views behave.
    func onEditingChanged(_ editing: Bool) {
        if editing {
            editingState = .began
        } else {
            editingState = .ended

            //Set the value here again to prompt its `didSet` implementation so that you can send the appropriate `.release` event.
            value = value
        }
    }

    private func resolveEventType() -> AUParameterAutomationEventType {
        let eventType: AUParameterAutomationEventType
        switch editingState {
        case .began:
            eventType = .touch
            editingState = .active
        case .ended:
            eventType = .release
            editingState = .inactive
        default:
            eventType = .value
        }
        return eventType
    }

    private enum EditingState {
        case inactive
        case began
        case active
        case ended
        case hostUpdate
    }
}

extension AUAudioUnit {
    // Can you subclass the parameter tree to set that on the `AUAudioUnit`?

    var observableParameterTree: ObservableAUParameterGroup? {
        guard let paramTree = self.parameterTree else { return nil }
        return ObservableAUParameterGroup(paramTree)
    }
}
