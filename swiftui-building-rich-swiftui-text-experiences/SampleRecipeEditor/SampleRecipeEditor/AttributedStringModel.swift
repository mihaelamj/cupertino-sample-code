/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftData model for an attributed string that lazily performs serialization
  on saving.
*/

import SwiftData
import Foundation

/// A SwiftData model for storing attributed strings, preserving all attributes
/// in a configurable attribute scope.
@Model
final class AttributedStringModel: Identifiable {
    @Transient
    lazy var value: AttributedString = initializeValue() {
        didSet {
            valueChanged = true
        }
    }

    @Transient
    private var valueChanged: Bool = false

    @Attribute(.externalStorage)
    private var data: Data

    private var scope: Scope

    /// Create a new SwiftData model for the given attributed string.
    ///
    /// The model preserves any attributes in the given scope when SwiftData
    /// persists the model in between app launches.
    init(value: AttributedString, scope: Scope) {
        self.data = Data()
        self.scope = scope
        self.value = value

        // Add observer for the case where the app's logic manually instantiates
        // the model.
        NotificationCenter.default.addObserver(
            self, selector: #selector(willSave),
            name: ModelContext.willSave, object: nil)
    }

    private func initializeValue() -> AttributedString {
        // Add observer for the case where SwiftData's synthesized initializer
        // instantiates the model.
        NotificationCenter.default.addObserver(
            self, selector: #selector(willSave),
            name: ModelContext.willSave, object: nil)

        do {
            let string = try JSONDecoder().decode(
                AttributedString.self,
                from: data,
                configuration: scope.decodingConfiguration)
            // Real-world apps may need better logging infrastructure.
            print("Loaded attributed string:\n\(string)")
            return string
        } catch {
            // Real-world apps may need better error handling.
            print(error)
            return ""
        }
    }

    @objc
    private func willSave() {
        guard valueChanged else {
            return
        }
        valueChanged = false

        do {
            self.data = try JSONEncoder().encode(
                value,
                configuration: scope.encodingConfiguration)
            // Real-world apps may need better logging infrastructure.
            print("Saved attributed string:\n\(value)")
        } catch {
            // Real-world apps may need better error handling.
            print(error)
        }
    }
}

extension AttributedStringModel {
    /// An enum listing all the attribute scopes that this app's attributed
    /// string SwiftData model can serialize.
    enum Scope: String, Codable {
        /// The case representing `AttributeScopes.RecipeModelAttributes`.
        case recipe
        /// The case representing `AttributeScopes.IngredientNameAttributes`.
        case ingredient

        fileprivate var encodingConfiguration: AttributeScopeCodableConfiguration {
            switch self {
            case .recipe:
                AttributeScopes.RecipeModelAttributes.encodingConfiguration
            case .ingredient:
                AttributeScopes.IngredientNameAttributes.encodingConfiguration
            }
        }

        fileprivate var decodingConfiguration: AttributeScopeCodableConfiguration {
            switch self {
            case .recipe:
                AttributeScopes.RecipeModelAttributes.decodingConfiguration
            case .ingredient:
                AttributeScopes.IngredientNameAttributes.decodingConfiguration
            }
        }
    }
}
