/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main user interface.
*/

import SwiftUI
import Accessibility

struct ContentView: View {
    
    @State private var callAudio = CallAudio()
    @State private var speechSynth = SpeechSynthesizer()
    
    @State private var userProvidedText = ""
    @State private var addAudioToCalls = false
    
    @State private var showAccessibilityAlert = false
    @State private var showPermissionDeniedAlert = false
    
    struct AlertInfo {
        let title: String
        let description: String
    }
    
    private let accessibilityAlert = AlertInfo(title: "Permission required to send audio to call",
                                               description: "Apps are currently not allowed to add their audio to calls. Would you like to open the Settings app to enable the setting, 'Allow apps to Add Audio to Calls'?")
    
    private let permissionAlert = AlertInfo(title: "Permission denied",
                                            description: "The app does not have permission to inject spoken audio. Would you like to open the Settings app to enabled permission?")
    
    // A custom binding for the Toggle button.
    private var toggleBinding: Binding<Bool> {
        Binding {
            addAudioToCalls
        } set: { newValue in
            Task {
                // Set the state of spoken audio injection.
                switch await callAudio.setAppAudioEnabled(newValue) {
                case .success(let state):
                    // Update the toggle state to match the feature enablement state.
                    addAudioToCalls = state
                case .failure(let error):
                    switch error {
                    case .serviceDisabled:
                        // The service is in a disabled state. Show an informational alert.
                        showAccessibilityAlert = true
                    case .permissionDenied:
                        // A person denied the app permission. Show an informational alert.
                        showPermissionDeniedAlert = true
                    default: ()
                    }
                    // Set the toggle state to off.
                    addAudioToCalls = false
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Type to speak...", text: $userProvidedText)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(false)
                    .font(.system(size: 24, weight: .medium))
                    .onSubmit {
                        textToSpeech(text: userProvidedText)
                    }
                Spacer()
            }
            .padding([.top], 100)
            .padding([.leading, .trailing])
            .toolbar {
                // When a call is active, show a pulsing phone icon in the toolbar.
                if callAudio.isCallActive {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Image(systemName: "phone.connection.fill")
                            .symbolEffect(.pulse, isActive: callAudio.isCallActive)
                            .font(.system(size: 20, weight: .light))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Toggle("Add Audio To Call", isOn: toggleBinding)
                        .toggleStyle(.button)
                }
            }
        }
        // Show an accessibility alert.
        .alert(accessibilityAlert.title, isPresented: $showAccessibilityAlert) {
            alertButtons
        } message: {
            Text(accessibilityAlert.description)
        }
        // Show a permission denied alert.
        .alert(permissionAlert.title, isPresented: $showPermissionDeniedAlert) {
            alertButtons
        } message: {
            Text(permissionAlert.description)
        }
    }
    
    // Standard buttons to display in the alert dialogs.
    @ViewBuilder
    var alertButtons: some View {
        Button("Open Settings") {
            Task {
                do {
                    // Open the configuration screen for this feature in the Settings app.
                    try await AccessibilitySettings.openSettings(for: .allowAppsToAddAudioToCalls)
                } catch {
                    print("Unable to open Settings app: \(error)")
                }
            }
        }
        Button("Cancel", role: .cancel) {}
    }
    
    /// Speaks the specified string of text.
    /// - Parameter text: The text to speak.
    func textToSpeech(text: String) {
        Task {
            await speechSynth.synthesizeSpeech(text: text)
            userProvidedText = ""
        }
    }
}

#Preview {
    ContentView()
}
