/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ContentView represents the main view of the application and is the view which is configured
 by the SimpleURLFilterApp as the view used by the main WindowGroup and Scene.
 In this view the status of the network filter is presented as well as any error messages.
 A "Configure" button presents the ConfigurationView where the network filter configuration
 parameters can be viewed and changed.
 An "Enable"/"Disable" button allows for quick access to enable and disable the filter.
 Additionally, a utility menu is presented to allow an interface to interact with other
 aspects of the underlying NEURLFilterManager API.
 The ContentView listens for changes in the `scenePhase` and refreshes state from the
 underlying API when the scene indicates the app has become active. This keeps the interface
 in up do date and representative of the status of the filter.
 ContentView maintains an `ActivityState` which is used to give feedback on the progress
 and state of various activities the user can perform.
*/

import SwiftUI
import OSLog

extension ContentView {
    static let activityStateClearTimeInterval: TimeInterval = 3
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ConfigurationModel.self) var configurationModel
    @State var editorPresented = false
    @State var presentErrorAlert = false
    @State var errorDetails: ErrorDetails?
    @State var activityState = ActivityState.idle
    @State var activityStateTimer = Timer.publish(every: Self.activityStateClearTimeInterval, on: .main, in: .common).autoconnect()

    @ScaledMetric var networkImageSize = 100
    @ScaledMetric var activityMessageHeight = 30

    var body: some View {
        NavigationStack {
            VStack {
                mainImageView()
                statusView()
                errorView()
                // The spacer gives a flexible space to add and remove the error presentation.
                Spacer()
                actionView()
            }
            .frame(maxWidth: 400)
            .sheet(isPresented: $editorPresented) {
                // Create an explicit binding from the Environment configurationModel.
                @Bindable var configurationModel = configurationModel
                ConfigurationView(configuration: $configurationModel.currentConfiguration)
                    .environment(configurationModel)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Menu {
                        Button("Reload Configuration", systemImage: "arrow.trianglehead.2.clockwise.rotate.90.circle") {
                            refreshConfiguration()
                        }
                        Button("Reset PIR Cache", systemImage: "arrow.counterclockwise.circle") {
                            resetPIRCache()
                        }
                        Button("Refresh PIR Parameters", systemImage: "arrow.up.arrow.down.circle") {
                            refreshPIRParameters()
                        }
                        Button("Remove Filter", systemImage: "xmark.shield.fill", role: .destructive) {
                            removeCurrentConfiguration()
                        }
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                }
            }
        }
        .alert(
            errorDetails?.title ?? "Error", isPresented: $presentErrorAlert, presenting: errorDetails, actions: { _ in },
            message: { details in
                Text(details.message)
            }
        )
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                // Refresh state when the app becomes active
                refreshConfiguration()
            }
        }
    }

    @ViewBuilder
    func mainImageView() -> some View {
        Image(systemName: networkImageName)
            .imageScale(.large)
            .foregroundStyle(.tint)
            .disabled(networkImageDisabled)
        // Giving this a frame helps the animations between different size symbols keep the UI steady and supports dynamic type.
            .frame(width: networkImageSize, height: networkImageSize)
            .font(.system(size: networkImageSize))
            .padding(.top, 150)
            .padding(.bottom, 20)
        // Animates when the status represents a transition.
            .symbolEffect(.pulse.byLayer, isActive: indeterminateStatus)
        // Animate when the image is changed.
            .contentTransition(.symbolEffect(.replace))
    }

    @ViewBuilder
    func statusView() -> some View {
        Text(statusMessage)
            .font(.largeTitle)
            .animation(.default, value: statusMessage)
        Text(activityMessage)
            .foregroundStyle(.secondary)
            .font(.subheadline)
            .frame(height: activityMessageHeight)
            .animation(.default, value: activityMessage)
            .onReceive(activityStateTimer) { _ in
                // When the timer fires, cancel it (it recurs), and update the activity state to idle to remove the activity message.
                activityStateTimer.upstream.connect().cancel()
                guard activityState != .idle else { return }
                activityState = ActivityState.idle
            }
            .onChange(of: activityState) {
                // When the activity state changes, cancel the current timer and restart a timer.
                activityStateTimer.upstream.connect().cancel()
                activityStateTimer = Timer.publish(every: Self.activityStateClearTimeInterval, on: .main, in: .common).autoconnect()
            }
    }

    @ViewBuilder
    func errorView() -> some View {
        if errorMessage != nil {
            // To provide a full width text background wrap in a VStack to enable different coloring from the outer stack.
            VStack {
                Text(errorMessage ?? "")
                    .foregroundStyle(.red)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.default, value: errorMessage)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial)
            )
            .padding()
        }
    }

    @ViewBuilder
    func actionView() -> some View {
        HStack {
            Button {
                currentConfiguration(enable: filterActivationButtonState.action == .enableFilter)
            } label: {
                Text(filterActivationButtonState.title)
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.bordered)
            .disabled(!filterActivationButtonState.enabled)
            .clipShape(Capsule())
            Button {
                editorPresented = true
            } label: {
                Text("Configure")
                    .frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(Capsule())
        }
        .padding()
    }

    private let log = Logger.createLogger(for: Self.self)
}

extension ContentView {

    func currentConfiguration(enable: Bool) {
        Task {
            do {
                activityState = enable ? .configurationEnableStart : .configurationDisableStart
                try await configurationModel.currentConfiguration(enable: enable)
                activityState = enable ? .configurationEnableEnd : .configurationDisableEnd
            } catch {
                log.error("Failed to \(enable ? "enable" : "disable") current configuration: \(error)")
                activityState = enable ? .configurationEnableFailed : .configurationDisableFailed
                presentErrorAlert = true
                errorDetails = ErrorDetails(title: "Unable to \(enable ? "Enable" : "Disable") Configuration",
                                            message: error.localizedDescription)
            }
        }
    }

    func refreshConfiguration() {
        Task {
            do {
                activityState = .configurationLoadStart
                try await configurationModel.refreshFromSystem()
                activityState = .configurationLoadEnd
            } catch {
                activityState = .configurationLoadFailed
                // Show an alert with the error.
                presentErrorAlert = true
                errorDetails = ErrorDetails(title: "Unable to Load Configuration", message: error.localizedDescription)
            }
        }
    }

    func resetPIRCache() {
        Task {
            do {
                activityState = .pirCacheResetStart
                try await configurationModel.resetPIRCache()
                activityState = .pirCacheResetEnd
            } catch {
                log.error("Failed to reset PIR cache: \(error)")
                activityState = .pirCacheResetFailed
                // Show an alert with the error.
                presentErrorAlert = true
                errorDetails = ErrorDetails(title: "Unable to Reset PIR Cache", message: error.localizedDescription)
            }
        }
    }

    func refreshPIRParameters() {
        Task {
            do {
                activityState = .pirParametersRefreshStart
                try await configurationModel.refreshPIRParameters()
                activityState = .pirParametersRefreshEnd
            } catch {
                log.error("Failed to refresh PIR parameters: \(error)")
                activityState = .pirParametersRefreshFailed
                // Show an alert with the error.
                presentErrorAlert = true
                errorDetails = ErrorDetails(title: "Unable to Refresh PIR Parameters", message: error.localizedDescription)
            }
        }
    }

    func removeCurrentConfiguration() {
        Task {
            do {
                activityState = .configurationRemoveStart
                try await configurationModel.removeCurrentConfiguration()
                activityState = .configurationRemoveEnd
            } catch {
                log.error("Failed to remove configuration: \(error)")
                activityState = .configurationRemoveFailed
                // Show an alert with the error.
                presentErrorAlert = true
                errorDetails = ErrorDetails(title: "Unable to Remove Configuration", message: error.localizedDescription)
            }
        }
    }

    var indeterminateStatus: Bool {
        switch configurationModel.filterStatus {
        case .starting, .stopping:
            return true
        default:
            return false
        }
    }

    enum ActivationButtonAction {
        case enableFilter
        case disableFilter
    }

    var statusMessage: String {
        switch configurationModel.filterStatus {
        case .unknown:
            return activityState.message
        case .disabled:
            return "Disabled"
        case .invalid:
            return "Not Configured"
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting"
        case .running:
            return "Running"
        case .stopping:
            return "Stopping"
        }
    }

    var activityMessage: String {
        return activityState.message
    }

    var errorMessage: String? {
        return configurationModel.filterStatus.errorMessage
    }

    var filterActivationButtonState: (enabled: Bool, title: String, action: ActivationButtonAction) {
        let enableFilter = !(configurationModel.currentConfiguration?.enabled ?? false)
        let title = enableFilter ? "Enable" : "Disable"
        let action: ActivationButtonAction = enableFilter ? .enableFilter : .disableFilter
        var buttonEnabled: Bool
        switch configurationModel.filterStatus {
        case .unknown, .invalid:
            buttonEnabled = false
        case .disabled, .stopped, .starting, .running, .stopping:
            buttonEnabled = true
        }
        return (enabled: buttonEnabled, title: title, action: action)
    }

    var networkImageName: String {
        switch configurationModel.filterStatus {
        case .running:
            return "network.badge.shield.half.filled"
        case .invalid:
            return "circle.badge.questionmark"
        case .stopped:
            return "network.slash"
        default:
            return "network"
        }
    }

    var networkImageDisabled: Bool {
        configurationModel.filterStatus == .disabled
    }
}

extension ActivityState {
    var message: String {
        switch self {
        case .idle:
            return ""
        case .configurationLoadStart:
            return "Loading configruation…"
        case .configurationLoadEnd:
            return "Configuration loaded"
        case .configurationLoadEmpty:
            return "No configuration"
        case .configurationLoadFailed:
            return "Failed to load configuration"
        case .configurationSaveStart:
            return "Applying configruation…"
        case .configurationSaveEnd:
            return "Configuration applied"
        case .configurationSaveFailed:
            return "Failed to apply configuration"
        case .configurationRemoveStart:
            return "Removing configruation…"
        case .configurationRemoveEnd:
            return "Configuration removed"
        case .configurationRemoveFailed:
            return "Failed to remove configuration"
        case .configurationEnableStart:
            return "Enabling configruation…"
        case .configurationEnableEnd:
            return "Configuration enabled"
        case .configurationEnableFailed:
            return "Failed to enable configuration"
        case .configurationDisableStart:
            return "Disabling configruation…"
        case .configurationDisableEnd:
            return "Configuration Disabled"
        case .configurationDisableFailed:
            return "Failed to disable configuration"
        case .pirCacheResetStart:
            return "Reseting PIR Cache…"
        case .pirCacheResetEnd:
            return "PIR Cache reset"
        case .pirCacheResetFailed:
            return "Failed to reset PIR Cache"
        case .pirParametersRefreshStart:
            return "Refreshing PIR Parameters…"
        case .pirParametersRefreshEnd:
            return "PIR Parameters refreshed"
        case .pirParametersRefreshFailed:
            return "Failed to refresh PIR Parameters"
        }
    }
}

#Preview {
    ContentView()
}
