/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model for maintaining the app state, including the underlying object capture state as well as any extra app state
 you maintain in addition, perhaps with invariants between them.
*/

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem,
                            category: "AppDataModel")

@MainActor
@Observable
class AppDataModel: Identifiable {
    static let instance = AppDataModel()

    /// When we start the capture phase, this will be set to the correct locations in the captureFolderManager.
    var objectCaptureSession: ObjectCaptureSession? {
        willSet {
            detachListeners()
        }
        didSet {
            guard objectCaptureSession != nil else { return }
            attachListeners()
        }
    }

    static let minNumImages = 10

    /// Once we are headed to reconstruction portion, we will hold the session here.
    private(set) var photogrammetrySession: PhotogrammetrySession?

    /// When we start a new capture, the folder will be set here.
    private(set) var captureFolderManager: CaptureFolderManager?

    /// Shows whether the user decided to skip reconstruction.
    private(set) var isSaveDraftEnabled = false

    var messageList = TimedMessageList()

    enum ModelState {
        case notSet
        case ready
        case capturing
        case prepareToReconstruct
        case reconstructing
        case viewing
        case completed
        case restart
        case failed
    }

    var state: ModelState = .notSet {
        didSet {
            logger.debug("didSet AppDataModel.state to \(String(describing: self.state))")
            performStateTransition(from: oldValue, to: state)
        }
    }

    var orbit: Orbit = .orbit1
    var isObjectFlipped: Bool = false

    var hasIndicatedObjectCannotBeFlipped: Bool = false
    var hasIndicatedFlipObjectAnyway: Bool = false
    var isObjectFlippable: Bool {
        // Override the objectNotFlippable feedback if the user has indicated
        // the object cannot be flipped or if they want to flip the object anyway
        guard !hasIndicatedObjectCannotBeFlipped else { return false }
        guard !hasIndicatedFlipObjectAnyway else { return true }
        guard let session = objectCaptureSession else { return true }
        return !session.feedback.contains(.objectNotFlippable)
    }

    enum CaptureMode: Equatable {
        case object
        case area
    }

    var captureMode: CaptureMode = .object

    // When state moves to failed, this is the error causing it.
    private(set) var error: Swift.Error?

    // Use setShowOverlaySheets(to:) to change this so you can maintain ObjectCaptureSession's pause state
    // properly because you don't hide the ObjectCaptureView. If you hide the ObjectCaptureView it pauses automatically.
    private(set) var showOverlaySheets = false

    // Shows whether the tutorial has played once during a session.
    var tutorialPlayedOnce = false

    // Postpone creating ObjectCaptureSession and PhotogrammetrySession until necessary.
    private init() {
        state = .ready
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppTermination(notification:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            self.detachListeners()
        }
    }

    /// Once reconstruction and viewing are complete, this should be called to let the app know it can go back to the new capture
    /// view.  We explicitly DO NOT destroy the model here to avoid transition state errors.  The splash screen will set up the
    /// AppDataModel to a clean slate when it starts.
    /// This can also be called after a cancelled or error reconstruction to go back to the start screen.
    func endCapture() {
        state = .completed
    }

    func removeCaptureFolder() {
        logger.log("Removing the capture folder...")
        guard let url = captureFolderManager?.captureFolder else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // Don't touch the showOverlaySheets directly, call setShowOverlaySheets() instead.
    // Since we use sheets and leave the ObjectCaptureView on screen and blur it underneath,
    // the session doesn't pause. We need to pause/resume the session by hand.
    func setShowOverlaySheets(to shown: Bool) {
        guard shown != showOverlaySheets else { return }
        if shown {
            showOverlaySheets = true
            objectCaptureSession?.pause()
        } else {
            objectCaptureSession?.resume()
            showOverlaySheets = false
        }
    }

    func saveDraft() {
        objectCaptureSession?.finish()
        isSaveDraftEnabled = true
    }

    // - MARK: Private Interface

    private var currentFeedback: Set<Feedback> = []

    private typealias Feedback = ObjectCaptureSession.Feedback
    private typealias Tracking = ObjectCaptureSession.Tracking

    private var tasks: [ Task<Void, Never> ] = []
}

extension AppDataModel {
    private func attachListeners() {
        logger.debug("Attaching listeners...")
        guard let model = objectCaptureSession else {
            fatalError("Logic error")
        }

        tasks.append(
            Task<Void, Never> { [weak self] in
                for await newFeedback in model.feedbackUpdates {
                    logger.debug("Task got async feedback change to: \(String(describing: newFeedback))")
                    self?.updateFeedbackMessages(for: newFeedback)
                }
                logger.log("^^^ Got nil from stateUpdates iterator!  Ending observation task...")
            })

        tasks.append(Task<Void, Never> { [weak self] in
            for await newState in model.stateUpdates {
                logger.debug("Task got async state change to: \(String(describing: newState))")
                self?.onStateChanged(newState: newState)
            }
            logger.log("^^^ Got nil from stateUpdates iterator!  Ending observation task...")
        })
    }

    private func detachListeners() {
        logger.debug("Detaching listeners...")
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
    }

    @objc
    private func handleAppTermination(notification: Notification) {
        logger.log("Notification for the app termination is received...")
        if state == .ready || state == .capturing {
            removeCaptureFolder()
        }
    }

    // Should be called when a new capture is to be created, before the session will be needed.
    private func startNewCapture() throws {
        logger.log("startNewCapture() called...")
        if !ObjectCaptureSession.isSupported {
            preconditionFailure("ObjectCaptureSession is not supported on this device!")
        }

        captureFolderManager = try CaptureFolderManager()
        objectCaptureSession = ObjectCaptureSession()

        guard let session = objectCaptureSession else {
            preconditionFailure("startNewCapture() got unexpectedly nil session!")
        }

        guard let captureFolderManager else {
            preconditionFailure("captureFolderManager unexpectedly nil!")
        }

        var configuration = ObjectCaptureSession.Configuration()
        configuration.isOverCaptureEnabled = true
        configuration.checkpointDirectory = captureFolderManager.checkpointFolder
        // Starts the initial segment and sets the output locations.
        session.start(imagesDirectory: captureFolderManager.imagesFolder,
                      configuration: configuration)

        if case let .failed(error) = session.state {
            logger.error("Got error starting session! \(String(describing: error))")
            switchToErrorState(error: error)
        } else {
            state = .capturing
        }
    }

    private func switchToErrorState(error inError: Swift.Error) {
        // Set the error first since the transitions will assume it is non-nil!
        error = inError
        state = .failed
    }

    // Moves from prepareToReconstruct to .reconstructing.
    // Should be called from the ReconstructionPrimaryView async task once it is on the screen.
    private func startReconstruction() throws {
        logger.debug("startReconstruction() called.")

        var configuration = PhotogrammetrySession.Configuration()
        if captureMode == .area {
            configuration.isObjectMaskingEnabled = false
        }

        guard let captureFolderManager else {
            preconditionFailure("captureFolderManager unexpectedly nil!")
        }

        configuration.checkpointDirectory = captureFolderManager.checkpointFolder
        photogrammetrySession = try PhotogrammetrySession(
            input: captureFolderManager.imagesFolder,
            configuration: configuration)

        state = .reconstructing
    }

    private func reset() {
        logger.info("reset() called...")
        photogrammetrySession = nil
        objectCaptureSession = nil
        captureFolderManager = nil
        showOverlaySheets = false
        orbit = .orbit1
        isObjectFlipped = false
        currentFeedback = []
        messageList.removeAll()
        captureMode = .object
        state = .ready
        isSaveDraftEnabled = false
        tutorialPlayedOnce = false
    }

    private func onStateChanged(newState: ObjectCaptureSession.CaptureState) {
        logger.info("OCViewModel switched to state: \(String(describing: newState))")
        if case .completed = newState {
            logger.log("ObjectCaptureSession moved in .completed state.")
            if isSaveDraftEnabled {
                logger.log("The data is stored. Closing the session...")
                reset()
            } else {
                logger.log("Switch app model to reconstruction...")
                state = .prepareToReconstruct
            }
        } else if case let .failed(error) = newState {
            logger.error("OCS moved to error state \(String(describing: error))...")
            if case ObjectCaptureSession.Error.cancelled = error {
                state = .restart
            } else {
                switchToErrorState(error: error)
            }
        }
    }

    private func updateFeedbackMessages(for feedback: Set<Feedback>) {
        // Compare the incoming feedback with the previous feedback to find the intersection.
        let persistentFeedback = currentFeedback.intersection(feedback)

        // Find the feedbacks that are not active anymore.
        let feedbackToRemove = currentFeedback.subtracting(persistentFeedback)
        for thisFeedback in feedbackToRemove {
            if let feedbackString = FeedbackMessages.getFeedbackString(for: thisFeedback, captureMode: captureMode) {
                messageList.remove(feedbackString)
            }
        }

        // Find the new feedbacks.
        let feebackToAdd = feedback.subtracting(persistentFeedback)
        for thisFeedback in feebackToAdd {
            if let feedbackString = FeedbackMessages.getFeedbackString(for: thisFeedback, captureMode: captureMode) {
                messageList.add(feedbackString)
            }
        }

        currentFeedback = feedback
    }

    private func performStateTransition(from fromState: ModelState, to toState: ModelState) {
        if fromState == toState { return }
        if fromState == .failed { error = nil }

        switch toState {
            case .ready:
                do {
                    try startNewCapture()
                } catch {
                    logger.error("Starting new capture failed!")
                }
            case .prepareToReconstruct:
                // Clean up the session to free GPU and memory resources.
                objectCaptureSession = nil
                do {
                    try startReconstruction()
                } catch {
                    logger.error("Reconstructing failed!")
                    switchToErrorState(error: error)
                }
            case .restart, .completed:
                reset()
            case .viewing:
                photogrammetrySession = nil

                removeCheckpointFolder()
            case .failed:
                logger.error("App failed state error=\(String(describing: self.error!))")
                // We will show error screen here
            default:
                break
        }
    }

    private func removeCheckpointFolder() {
        // Remove checkpoint folder to free up space now that the model is generated.
        if let captureFolderManager {
            DispatchQueue.global(qos: .background).async {
                try? FileManager.default.removeItem(at: captureFolderManager.checkpointFolder)
            }
        }
    }

    func determineCurrentOnboardingState() -> OnboardingState? {
        guard let session = objectCaptureSession else { return nil }

        switch captureMode {
            case .object:
                let orbitCompleted = session.userCompletedScanPass
                var currentState = OnboardingState.tooFewImages
                if session.numberOfShotsTaken >= AppDataModel.minNumImages {
                    switch orbit {
                        case .orbit1:
                            currentState = orbitCompleted ? .firstSegmentComplete : .firstSegmentNeedsWork
                        case .orbit2:
                            currentState = orbitCompleted ? .secondSegmentComplete : .secondSegmentNeedsWork
                        case .orbit3:
                            currentState = orbitCompleted ? .thirdSegmentComplete : .thirdSegmentNeedsWork
                        }
                }
                return currentState
            case .area:
                return .captureInAreaMode
        }
    }
}
