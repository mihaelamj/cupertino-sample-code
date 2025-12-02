/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that provides observable objects for the user's defaults database.
*/

public extension UserDefaults {
    /// An `ObservableObject` for a `UserDefaults` property that is KVO-observable.
    /// For a `UserDefaults` property to be KVO-observable, the following needs to be true:
    /// The property name needs to match the `UserDefaults` key.
    /// The property needs to have a mark of `@objc dynamic.
    class ObservableProperty<Value: Equatable>: ObservableObject {
        private var observedDefaults: UserDefaults
        private let keyPath: WritableKeyPath<UserDefaults, Value>
        private var observation: NSKeyValueObservation?

        @Published public var value: Value {
            didSet {
                if value != oldValue {
                    observedDefaults[keyPath: keyPath] = value
                }
            }
        }

        /// Constructs a `UserDefaults.ObservableProperty`
        /// - Parameters:
        ///   - observedDefaults: A `UserDefaults` instance to observe.
        ///   - keyPath: The keyPath to a KVO-observable property in the
        ///   `observedDefaults` parameter.
        ///   - defaultValue: A default value to use if the new observed value is nil.
        public init(_ observedDefaults: UserDefaults, keyPath: WritableKeyPath<UserDefaults, Value>, defaultValue: Value) {
            self.observedDefaults = observedDefaults
            self.keyPath = keyPath
            value = observedDefaults[keyPath: keyPath]
            observation = observedDefaults.observe(keyPath, options: [.new]) { [weak self] _, change in
                self?.value = change.newValue ?? defaultValue
            }
        }
    }
}
