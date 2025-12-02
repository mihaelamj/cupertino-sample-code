/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ConfigurationView presents a form-based interface displaying the various configuration
 parameters and providing a means to edit them. Field-level validation is performed to
 assist with providing the underlying service with correct parameter values.
 ConfigurationView keeps a binding to the configuration to monitor it for changes which
 may take place outside this view, and allow the user to decide what to do in the
 situation when these values differ from what is present in the form currently.
 To accomplish this, and to convert form values to correct types, the view maintains
 @State variables for the fields of the configuration, rather than binding directly to
 the configuration.
*/

import SwiftUI
import RegexBuilder
import OSLog

struct ConfigurationView: View {
    @Environment(ConfigurationModel.self) var configurationModel
    @Environment(\.dismiss) private var dismiss

    @Binding var configuration: Configuration?

    @State var pirServerURLString: String
    @State var pirPrivacyPassIssuerURLString: String
    @State var pirAuthenticationToken: String
    @State var enabled: Bool
    @State var shouldFailClosed: Bool
    @State var controlProviderBundleIdentifier: String?
    @State var selectedPrefetchInterval: PrefilterFetchInterval

    @State var presentErrorAlert = false
    @State var errorDetails: ErrorDetails?
    @State var canPresentConfigChangeAlert = true
    @State var presentConfigChangeAlert = false
    @State var pendingConfiguration: Configuration?
    @State var validationIssues = Set<Field>()
    @FocusState private var focusedField: Field?

    init(configuration: Binding<Configuration?>) {
        _configuration = configuration
        let config = configuration.wrappedValue

        pirServerURLString = config?.pirServerURL?.absoluteString ?? ""
        pirPrivacyPassIssuerURLString = config?.pirPrivacyPassIssuerURL?.absoluteString ?? ""
        pirAuthenticationToken = config?.pirAuthenticationToken ?? ""
        enabled = config?.enabled ?? false
        shouldFailClosed = config?.shouldFailClosed ?? false
        controlProviderBundleIdentifier = config?.controlProviderBundleIdentifier
        if let config, let interval = PrefilterFetchInterval(rawValue: config.prefilterFetchInterval) {
            selectedPrefetchInterval = interval
        } else {
            selectedPrefetchInterval = .minimum
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Form {

                    Section {
                        Toggle("Enabled", isOn: $enabled)
                    }

                    Section {
                        TextField("PIR Server URL", text: $pirServerURLString)
                            .focused($focusedField, equals: .pirServerURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                        TextField("PIR Privacy Pass Issuer URL (Optional)", text: $pirPrivacyPassIssuerURLString)
                            .focused($focusedField, equals: .pirPrivacyPassIssuerURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    } header: {
                        Text("PIR Server URLs")
                    } footer: {
                        VStack {
                            validationErrorView(for: .pirServerURL)
                            validationErrorView(for: .pirPrivacyPassIssuerURL)
                        }
                    }

                    Section {
                        TextField("Authentication Token", text: $pirAuthenticationToken)
                            .focused($focusedField, equals: .pirAuthenticationToken)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    } header: {
                        Text("Authentication Token")
                    } footer: {
                        validationErrorView(for: .pirAuthenticationToken)
                    }

                    Section {
                        Picker("Pre-filter Fetch Frequency", selection: $selectedPrefetchInterval) {
                            ForEach(PrefilterFetchInterval.allCases) { interval in
                                Text(interval.label)
                            }
                        }
                    }

                    Section {
                        Toggle("Fail Closed", isOn: $shouldFailClosed)
                    } footer: {
                        Text("Block access upon the filter failing to make a filtering decision (e.g. communication failure with the PIR server)")
                    }

                    Section {
                    } footer: {
                        VStack {
                            Group {
                                Text("Control Provider Bundle Identifier")
                                    .textCase(.uppercase)
                                Text(controlProviderBundleIdentifier ?? "(Not set)")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .navigationTitle("Network Filter Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        Task {
                            do {
                                log.info("Applying configuration")
                                try await saveConfiguration()
                                dismiss()
                            } catch let error as ValidationError {
                                log.error("Failed to save configuration: \(error)")
                                // Show an alert with the validation error message.
                                presentErrorAlert = true
                                errorDetails = ErrorDetails(title: "Configuration Error", message: "Please correct errors in configuration.")
                            } catch {
                                log.error("Failed to save configuration: \(error)")
                                // Show an alert with the error message.
                                presentErrorAlert = true
                                errorDetails = ErrorDetails(title: "Unable to Apply Configuration", message: error.localizedDescription)
                            }
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            // Configuration change alert.
            .alert(
                "Overwrite Configuration?",
                isPresented: $presentConfigChangeAlert,
            ) {
                Button("Overwrite", role: .destructive) {
                    updateFrom(configuration: pendingConfiguration)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The configuration has changed, would you like to overwrite your edits with the current configuration?")
            }
            // Error alert.
            .alert(
                errorDetails?.title ?? "Error",
                isPresented: $presentErrorAlert,
                presenting: errorDetails
            ) { _ in
            } message: { details in
                Text(details.message)
            }
            // On focus lost for a field, validate the field so a validation message can be displayed.
            .onChange(of: focusedField, { oldValue, newValue in
                if let oldValue {
                    _ = try? validate([oldValue])
                }
            })
            // Monitor for system configuration changes.
            .onChange(of: configuration, { oldValue, newValue in
                if !workingConfigurationEqual(to: newValue) {
                    // Show alert indicating the configuration has changed and ask if the user
                    // wants to overwrite changes with the changed config, or keep their edits.
                    pendingConfiguration = newValue
                    // Only show the alert if configured to do so.
                    presentConfigChangeAlert = canPresentConfigChangeAlert
                }
            })
            // Disalow dismissal of this sheet in favor of the "Cancel" and "Apply" button actions.
            .interactiveDismissDisabled()
        }
    }

    @ViewBuilder
    func validationErrorView(for field: Field) -> some View {
        if validationIssues.contains(field) {
            Text(ValidationError.message(for: field))
                .foregroundStyle(.red)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private let log = Logger.createLogger(for: Self.self)
    private let urlMatcher = Regex {
        Capture {
            One(
                .url(
                    scheme: .required,
                    user: .optional,
                    password: .optional,
                    host: .required,
                    port: .optional,
                    path: .optional,
                    query: .optional,
                    fragment: .optional))
        }
    }
}

extension ConfigurationView {

    enum Field: CaseIterable {
        case pirServerURL
        case pirPrivacyPassIssuerURL
        case pirAuthenticationToken
    }

    enum ValidationError: Error {
        case validationFalied(Set<Field>)

        static func message(for field: Field) -> String {
            switch field {
            case .pirServerURL:
                return "Please enter a valid PIR server URL"
            case .pirPrivacyPassIssuerURL:
                return "Please enter a valid PIR Privacy Pass Issuer URL"
            case .pirAuthenticationToken:
                return "Please enter the PIR authentication token"
            }
        }
    }

    enum PrefilterFetchInterval: TimeInterval, CaseIterable, Identifiable {
        var id: Self { self }

        case minimum = 2700  // 60 * 45 (45 minutes).
        case oneHour = 3600  // 60 * 60 (60 minutes).
        case threeHours = 10_800  // 60 * 60 * 3 (3 hours).
        case sixHours = 21_600  // 60 * 60 * 6 (6 hours).
        case twelveHours = 43_200  // 60 * 60 * 12 (12 hours).
        case twentyfourHours = 86_400  // 60 * 60 * 24 (24 hours).

        var label: String {
            switch self {
            case .minimum:
                return "45 minutes"
            case .oneHour:
                return "1 hour"
            case .threeHours:
                return "3 hours"
            case .sixHours:
                return "6 hours"
            case .twelveHours:
                return "12 hours"
            case .twentyfourHours:
                return "24 hours"
            }
        }
    }

    func saveConfiguration() async throws {

        // Validate the given values.
        let validations = try validate()

        // Get validated values from the validate operation.
        guard let pirServerURL = validations[.pirServerURL] as? URL,
              let pirAuthenticationToken = validations[.pirAuthenticationToken] as? String?
        else {
            throw ValidationError.validationFalied(validationIssues)
        }
        let pirPrivacyPassIssuerURL = validations[.pirPrivacyPassIssuerURL] as? URL

        // Create a new configuration with our values.
        let configuration = Configuration(
            enabled: enabled,
            shouldFailClosed: shouldFailClosed,
            prefilterFetchInterval: selectedPrefetchInterval.rawValue,
            controlProviderBundleIdentifier: controlProviderBundleIdentifier,
            pirServerURL: pirServerURL,
            pirPrivacyPassIssuerURL: pirPrivacyPassIssuerURL,
            pirAuthenticationToken: pirAuthenticationToken)

        // Avoid presenting the configuration change alert while we are saving the configuration.
        canPresentConfigChangeAlert = false
        defer {
            canPresentConfigChangeAlert = true
        }
        // Save the configuration.
        try await configurationModel.save(configuration: configuration)
    }

    // Returns a dictionary keyed off of Field with the validated value as the dictionary value.
    func validate(_ fields: Set<Field>? = nil) throws(ValidationError) -> [Field: Any] {
        let validationFields = fields ?? Set(Field.allCases)
        var validations = [Field: Any]()
        var valid = true

        for field in validationFields {
            switch field {
            case .pirServerURL:
                if pirServerURLString.firstMatch(of: urlMatcher) != nil, let pirServerURL = URL(string: pirServerURLString) {
                    validationIssues.remove(.pirServerURL)
                    validations[field] = pirServerURL
                } else {
                    validationIssues.insert(.pirServerURL)
                    valid = false
                }
            case .pirAuthenticationToken:
                let token = pirAuthenticationToken.trimmingCharacters(in: .whitespacesAndNewlines)
                if token.isEmpty {
                    validationIssues.insert(.pirAuthenticationToken)
                    valid = false
                } else {
                    validationIssues.remove(.pirAuthenticationToken)
                    validations[field] = token
                }
            case .pirPrivacyPassIssuerURL:
                if !pirPrivacyPassIssuerURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if pirPrivacyPassIssuerURLString.firstMatch(of: urlMatcher) != nil, let url = URL(string: pirPrivacyPassIssuerURLString) {
                        validationIssues.remove(.pirPrivacyPassIssuerURL)
                        validations[field] = url
                    } else {
                        validationIssues.insert(.pirPrivacyPassIssuerURL)
                        valid = false
                    }
                } else {
                    validationIssues.remove(.pirPrivacyPassIssuerURL)
                    validations[field] = nil
                }
            }
        }

        if !valid {
            throw ValidationError.validationFalied(validationIssues)
        }

        return validations
    }

    func workingConfigurationEqual(to configuration: Configuration?) -> Bool {
        var equal =
        pirServerURLString == configuration?.pirServerURL?.absoluteString ?? ""
        && pirPrivacyPassIssuerURLString == configuration?.pirPrivacyPassIssuerURL?.absoluteString ?? ""
        && pirAuthenticationToken == configuration?.pirAuthenticationToken ?? ""
        && enabled == configuration?.enabled ?? false
        && shouldFailClosed == configuration?.shouldFailClosed ?? false
        // Omit controlProviderBundleIdentifier, as this is not user editable.

        if let configuration, let interval = PrefilterFetchInterval(rawValue: configuration.prefilterFetchInterval) {
            equal = equal && selectedPrefetchInterval == interval
        } else {
            equal = equal && selectedPrefetchInterval == .minimum
        }
        return equal
    }

    private func updateFrom(configuration: Configuration?) {
        pirServerURLString = configuration?.pirServerURL?.absoluteString ?? ""
        pirPrivacyPassIssuerURLString = configuration?.pirPrivacyPassIssuerURL?.absoluteString ?? ""
        pirAuthenticationToken = configuration?.pirAuthenticationToken ?? ""
        enabled = configuration?.enabled ?? false
        shouldFailClosed = configuration?.shouldFailClosed ?? false
        controlProviderBundleIdentifier = configuration?.controlProviderBundleIdentifier
        if let configuration, let interval = PrefilterFetchInterval(rawValue: configuration.prefilterFetchInterval) {
            selectedPrefetchInterval = interval
        } else {
            selectedPrefetchInterval = .minimum
        }
    }
}
