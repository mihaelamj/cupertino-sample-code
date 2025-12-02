/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Handle Automatic Assessment Mode via buttons in the toolbar.
*/

import Cocoa
import AutomaticAssessmentConfiguration

// Add the @objc attribute to be able to share a storyboard between Swift and Objective-C.
@objc(WindowController)
class WindowController: NSWindowController {
    var session: AEAssessmentSession?
    
    let calculatorBundleID = "com.apple.calculator"
    let dictionaryBundleID = "com.apple.Dictionary"
    
    @IBOutlet weak var lockUnlockItem: NSToolbarItem!
    
    @IBOutlet weak var calculatorOptions: NSSegmentedControl!
    @IBOutlet weak var dictionaryOptions: NSSegmentedControl!
        
    override func windowDidLoad() {
        super.windowDidLoad()
                
        // Arrange to remember the window location.
        window?.setFrameAutosaveName("Assessment Time")
        
        // Initially, Dictionary and Calculator are allowed; make sure the buttons reflect this.
        calculatorOptions.selectedSegment = 1
        dictionaryOptions.selectedSegment = 1
                
        // Set up an assessment session and, optionally, additional participants.
        setupAssessmentSession()
        
        // Update the lock button to indicate whether the session is locked.
        // Initially, it won't be.
        updateLockButton()
    }
        
    // Prepare an assessment session and configure it.
    func setupAssessmentSession() {
        
        let config = participantConfiguration()
        session = AEAssessmentSession(configuration: config)
        session?.delegate = self
    }
    
    // Create an appropriate configuration.
    // When running a version of macOS earlier than macOS 12, return a generic configuration that allows only this app.
    // For macOS 12 or later, additionally allow (or disallow) Calculator and Dictionary as participant apps.
    func participantConfiguration() -> AEAssessmentConfiguration {
        
        // Start with an assessment configuration.
        let config = AEAssessmentConfiguration()
        
        self.log("Building new assessment configuration.")
        
        if #available(macOS 12, *) {
            
            // Create two different participant configurations - one that allows
            // network access, and one that doesn't.
            let networkAllowedConfig = AEAssessmentParticipantConfiguration()
            networkAllowedConfig.allowsNetworkAccess = true
            
            let noNetworkConfig = AEAssessmentParticipantConfiguration()
            noNetworkConfig.allowsNetworkAccess = false
            
            // For Calculator and Dictionary: Create an AEAssessmentApplication
            //   and add it to the configuration, using either the `networkAllowed`
            //   or `noNetwork` config, according to the selected option in the UI.
            let calculator = AEAssessmentApplication(bundleIdentifier: calculatorBundleID)
            let dictionary = AEAssessmentApplication(bundleIdentifier: dictionaryBundleID)

            switch calculatorOptions.selectedSegment {
            case 0: // Not allowed.
                self.log("Calculator will not be allowed when locked.")
            case 1: // Allowed, no network.
                self.log("Calculator will be allowed when locked, with no network access.")
                config.setConfiguration(noNetworkConfig, for: calculator)
            case 2: // Allowed, with network.
                self.log("Calculator will be allowed when locked, with network access.")
                config.setConfiguration(networkAllowedConfig, for: calculator)
            default:
                self.log("Unexpected segment; Calculator not allowed.")
            }
            
            switch dictionaryOptions.selectedSegment {
            case 0: // Not allowed.
                self.log("Dictionary will not be allowed when locked.")
            case 1: // Allowed, no network.
                self.log("Dictionary will be allowed when locked, with no network access.")
                config.setConfiguration(noNetworkConfig, for: dictionary)
            case 2: // Allowed, with network.
                self.log("Dictionary will be allowed when locked, with network access.")
                config.setConfiguration(networkAllowedConfig, for: dictionary)
            default:
                self.log("Unexpected segment; Dictionary not allowed.")
            }

        } else {
            log("AEAssessmentApplication is not available before macOS 12.0.  Creating a generic configuration which allows this app only.")
        }
        return config
    }

    // Try opening an app with a particular bundle ID.
    // It'll most likely succeed, but in macOS 12, it'll only appear in an assessment session
    // if that app has been configured as a participant.
    func attemptToOpenAppWithBundleID(_ bundleID: String ) {
        
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            self.log("Attempting to open bundle \(bundleID) from \(url).")
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration() ) { app, error in
                if app != nil {
                    self.log("App \(bundleID) successfully launched.")
                } else {
                    self.log("App launch error: \(error?.localizedDescription ?? "no error"))")
                }
            }
        }
    }
    
    // The Calculator and Dictionary toolbar controls call this;
    // reset the participant configuration, and attempt to reopen the apps.
    @IBAction func updateConfiguration(_ sender: Any) {
        if #available(macOS 12, *) {
            session?.update(to: participantConfiguration())
        } else {
            self.log("Participant configuration options are macOS 12 only.")
        }
        attemptToOpenAppWithBundleID(calculatorBundleID)
        attemptToOpenAppWithBundleID(dictionaryBundleID)
    }

    // The Lock Session button begins and ends an assessment session.
    @IBAction func lockSession(_ sender: Any) {
        log("Lock Session.")
        
        if let currentSession = session, currentSession.isActive {
            log("Requesting session end.")
            session?.end()
        } else {
            log("Requesting session begin")
            session?.begin()
        }
    }

    // Change the lock button icon and text to match the current assessment state.
    func updateLockButton() {
        // Currently locked? Show the lock icon.
        if let currentSession = session, currentSession.isActive {
            lockUnlockItem.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "Unlock Session")
            lockUnlockItem.label = "Unlock"
        } else {
            lockUnlockItem.image = NSImage(systemSymbolName: "lock.open.fill", accessibilityDescription: "Lock Session")
            lockUnlockItem.label = "Lock"
        }
    }

    // Log a message by sending it to the Notification Center, in case anything
    // (like the LogViewController) is listening.
    func log(_ message: String) {

        // Post it, in case anybody is listening.
        NotificationCenter.default.post(name: NSNotification.Name("LogThis"), object: message)
    }
}

extension WindowController: AEAssessmentSessionDelegate {
    // Log that assessment delegate events happened.
    func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
        log("assessmentSessionDidBegin")
        updateLockButton()
    }
    
    func assessmentSession(_ session: AEAssessmentSession, failedToBeginWithError error: Error) {
        log("Session failed to begin - \(error.localizedDescription)")
        updateLockButton()
    }
    
    // During assessment, the sessionʼs delegate might receive an assessmentSession(_:was InterruptedWithError:) callback
    // to indicate a failure. If this happens, immediately stop the assessment, hide all sensitive content, and end the session.
    // Because it might take time for your app to finalize the assessment, the session relies on your app to call the sessionʼs end() method:
    func assessmentSession(_ session: AEAssessmentSession, wasInterruptedWithError error: Error) {
        log("Session Interrupted - \(error.localizedDescription)")
        log("Ending session")
        session.end()
        updateLockButton()
    }
    
    func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
        log("assessmentSessionDidEnd")
        updateLockButton()
    }
    
    func assessmentSession(_ session: AEAssessmentSession, failedToUpdateTo configuration: AEAssessmentConfiguration, error: Error) {
        log("Session failed to update to configuration \(configuration): \(error.localizedDescription)")
    }
    
}
