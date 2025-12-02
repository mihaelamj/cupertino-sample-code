/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that introduces the purpose of the app to users.
*/

import MusicKit
import SwiftUI

// MARK: - Welcome view

/// `WelcomeView` is a view that introduces to users the purpose of the MusicAlbums app,
/// and demonstrates best practices for requesting user consent for an app to get access to
/// Apple Music data.
///
/// Present this view as a sheet using the convenience `.welcomeSheet()` modifier.
struct WelcomeView: View {
    
    // MARK: - Properties
    
    /// The current authorization status of MusicKit.
    @Binding var musicAuthorizationStatus: MusicAuthorization.Status
    
    /// Opens a URL using the appropriate system service.
    @Environment(\.openURL) private var openURL
    
    // MARK: - View
    
    /// A declaration of the UI that this view presents.
    var body: some View {
        ZStack {
            gradient
            VStack {
                Text("Music Albums")
                    .foregroundColor(.primary)
                    .font(.largeTitle.weight(.semibold))
                    .shadow(radius: 2)
                    .padding(.bottom, 1)
                Text("Rediscover your old music.")
                    .foregroundColor(.primary)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .shadow(radius: 1)
                    .padding(.bottom, 16)
                explanatoryText
                    .foregroundColor(.primary)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .shadow(radius: 1)
                    .padding([.leading, .trailing], 32)
                    .padding(.bottom, 16)
                if let secondaryExplanatoryText = self.secondaryExplanatoryText {
                    secondaryExplanatoryText
                        .foregroundColor(.primary)
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .shadow(radius: 1)
                        .padding([.leading, .trailing], 32)
                        .padding(.bottom, 16)
                }
                if musicAuthorizationStatus == .notDetermined || musicAuthorizationStatus == .denied {
                    Button(action: handleButtonPressed) {
                        buttonText
                            .padding([.leading, .trailing], 10)
                    }
                    .buttonStyle(.prominent)
                    .colorScheme(.light)
                }
            }
            .colorScheme(.dark)
        }
    }
    
    /// Constructs a gradient to use as the view background.
    private var gradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: (130.0 / 255.0), green: (109.0 / 255.0), blue: (204.0 / 255.0)),
                Color(red: (130.0 / 255.0), green: (130.0 / 255.0), blue: (211.0 / 255.0)),
                Color(red: (131.0 / 255.0), green: (160.0 / 255.0), blue: (218.0 / 255.0))
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .flipsForRightToLeftLayoutDirection(false)
        .ignoresSafeArea()
    }
    
    /// Provides text that explains how to use the app according to the authorization status.
    private var explanatoryText: Text {
        let explanatoryText: Text
        switch musicAuthorizationStatus {
            case .restricted:
                explanatoryText = Text("Music Albums cannot be used on this iPhone because usage of ")
                    + Text(Image(systemName: "applelogo")) + Text(" Music is restricted.")
            default:
                explanatoryText = Text("Music Albums uses ")
                    + Text(Image(systemName: "applelogo")) + Text(" Music\nto help you rediscover your music.")
        }
        return explanatoryText
    }
    
    /// Provides additional text that explains how to get access to Apple Music
    /// after previously denying authorization.
    private var secondaryExplanatoryText: Text? {
        var secondaryExplanatoryText: Text?
        switch musicAuthorizationStatus {
            case .denied:
                secondaryExplanatoryText = Text("Please grant Music Albums access to ")
                    + Text(Image(systemName: "applelogo")) + Text(" Music in Settings.")
            default:
                break
        }
        return secondaryExplanatoryText
    }
    
    /// A button that the user taps to continue using the app according to the current
    /// authorization status.
    private var buttonText: Text {
        let buttonText: Text
        switch musicAuthorizationStatus {
            case .notDetermined:
                buttonText = Text("Continue")
            case .denied:
                buttonText = Text("Open Settings")
            default:
                fatalError("No button should be displayed for current authorization status: \(musicAuthorizationStatus).")
        }
        return buttonText
    }
    
    // MARK: - Methods
    
    /// Allows the user to authorize Apple Music usage when tapping the Continue/Open Setting button.
    private func handleButtonPressed() {
        switch musicAuthorizationStatus {
            case .notDetermined:
                Task {
                    let musicAuthorizationStatus = await MusicAuthorization.request()
                    await update(with: musicAuthorizationStatus)
                }
            case .denied:
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            default:
                fatalError("No button should be displayed for current authorization status: \(musicAuthorizationStatus).")
        }
    }
    
    /// Safely updates the `musicAuthorizationStatus` property on the main thread.
    @MainActor
    private func update(with musicAuthorizationStatus: MusicAuthorization.Status) {
        withAnimation {
            self.musicAuthorizationStatus = musicAuthorizationStatus
        }
    }
    
    // MARK: - Presentation coordinator
    
    /// A presentation coordinator to use in conjuction with `SheetPresentationModifier`.
    class PresentationCoordinator: ObservableObject {
        static let shared = PresentationCoordinator()
        
        private init() {
            let authorizationStatus = MusicAuthorization.currentStatus
            musicAuthorizationStatus = authorizationStatus
            isWelcomeViewPresented = (authorizationStatus != .authorized)
        }
        
        @Published var musicAuthorizationStatus: MusicAuthorization.Status {
            didSet {
                isWelcomeViewPresented = (musicAuthorizationStatus != .authorized)
            }
        }
        
        @Published var isWelcomeViewPresented: Bool
    }
    
    // MARK: - Sheet presentation modifier
    
    /// A view modifier that changes the presentation and dismissal behavior of the welcome view.
    fileprivate struct SheetPresentationModifier: ViewModifier {
        @StateObject private var presentationCoordinator = PresentationCoordinator.shared
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $presentationCoordinator.isWelcomeViewPresented) {
                    WelcomeView(musicAuthorizationStatus: $presentationCoordinator.musicAuthorizationStatus)
                        .interactiveDismissDisabled()
                }
        }
    }
}

// MARK: - View extension

/// Allows the addition of the`welcomeSheet` view modifier to the top-level view.
extension View {
    func welcomeSheet() -> some View {
        modifier(WelcomeView.SheetPresentationModifier())
    }
}

// MARK: - Previews

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(musicAuthorizationStatus: .constant(.notDetermined))
    }
}
