/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The buttons on the review screen.
*/

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: GuidedCaptureSampleApp.subsystem, category: "OnboardingButtonView")

/// The view that creates the buttons on the review screen, depending on `currentState` in `onboardingStateMachine`.
struct OnboardingButtonView: View {
    @Environment(AppDataModel.self) var appModel
    var session: ObjectCaptureSession
    var onboardingStateMachine: OnboardingStateMachine
    @Binding var showOnboardingView: Bool
    @Binding var showShotLocations: Bool

    @State private var userHasIndicatedObjectCannotBeFlipped: Bool? = nil
    @State private var userHasIndicatedFlipObjectAnyway: Bool? = nil

    var body: some View {
        VStack {
            HStack {
                CancelButton(buttonLabel: LocalizedString.cancel, showOnboardingView: $showOnboardingView)
                    .padding(.leading)
                Spacer()
                CameraToggleButton(showShotLocations: $showShotLocations)
                    .padding([.top, .trailing])
                    .opacity(isTutorialPlaying ? 0.0 : 1.0)
            }

            Spacer()

            VStack(spacing: 0) {
                let currentStateInputs = onboardingStateMachine.currentStateInputs()
                if currentStateInputs.contains(where: { $0 == .continue(isFlippable: false) || $0 == .continue(isFlippable: true) }) {
                    CreateButton(buttonLabel: LocalizedString.continue,
                                 buttonLabelColor: .white,
                                 shouldApplyBackground: true,
                                 action: { transition(with: .continue(isFlippable: appModel.isObjectFlippable)) }
                    )
                }
                if currentStateInputs.contains(where: { $0 == .flipObjectAnyway }) {
                    CreateButton(buttonLabel: LocalizedString.flipAnyway,
                                 buttonLabelColor: .blue,
                                 action: {
                        userHasIndicatedFlipObjectAnyway = true
                        transition(with: .flipObjectAnyway)
                    })
                }
                if currentStateInputs.contains(where: { $0 == .skip(isFlippable: false) || $0 == .skip(isFlippable: true) }) {
                    CreateButton(buttonLabel: LocalizedString.skip,
                                 buttonLabelColor: .blue,
                                 action: {
                        transition(with: .skip(isFlippable: appModel.isObjectFlippable))
                    })
                }
                if currentStateInputs.contains(where: { $0 == .finish }) {
                    let buttonLabel = appModel.captureMode == .area ? LocalizedString.process : LocalizedString.finish
                    let buttonLabelColor: Color = appModel.captureMode == .area ? .white :
                        (onboardingStateMachine.currentState == .thirdSegmentComplete ? .white : .blue)
                    let shouldApplyBackground = appModel.captureMode == .area ? true : (onboardingStateMachine.currentState == .thirdSegmentComplete)
                    let showBusyIndicator = session.state == .finishing && !appModel.isSaveDraftEnabled ? true : false
                    CreateButton(buttonLabel: buttonLabel,
                                 buttonLabelColor: buttonLabelColor,
                                 shouldApplyBackground: shouldApplyBackground,
                                 showBusyIndicator: showBusyIndicator,
                                 action: { [weak session] in session?.finish() })
                }
                if currentStateInputs.contains(where: { $0 == .objectCannotBeFlipped }) {
                    CreateButton(buttonLabel: LocalizedString.cannotFlipYourObject,
                                 buttonLabelColor: .blue,
                                 action: {
                        userHasIndicatedObjectCannotBeFlipped = true
                        transition(with: .objectCannotBeFlipped)
                    })
                }
                if onboardingStateMachine.currentState == OnboardingState.tooFewImages ||
                    onboardingStateMachine.currentState == .secondSegmentComplete  ||
                    onboardingStateMachine.currentState == .thirdSegmentComplete {
                    CreateButton(buttonLabel: "", action: {})
                }
                if currentStateInputs.contains(where: { $0 == .saveDraft }) {
                    let showBusyIndicator = session.state == .finishing && appModel.isSaveDraftEnabled ? true : false
                    CreateButton(buttonLabel: LocalizedString.saveDraft,
                                 buttonLabelColor: .blue,
                                 showBusyIndicator: showBusyIndicator,
                                 action: { [weak appModel] in
                        appModel?.saveDraft()
                    })
                }
            }
            .padding(.bottom)
        }
    }

    private var isTutorialPlaying: Bool {
        switch onboardingStateMachine.currentState {
            case .flipObject, .flipObjectASecondTime, .captureFromLowerAngle, .captureFromHigherAngle:
                return true
            default:
                return false
        }
    }

    private func reloadData() {
        switch onboardingStateMachine.currentState {
            case .firstSegment, .dismiss:
                showOnboardingView = false
            case .secondSegment, .thirdSegment, .additionalOrbitOnCurrentSegment:
                beginNewOrbitOrSection()
            default:
                break
        }
    }

    private func beginNewOrbitOrSection() {
        if let userHasIndicatedObjectCannotBeFlipped {
            appModel.hasIndicatedObjectCannotBeFlipped = userHasIndicatedObjectCannotBeFlipped
        }

        if let userHasIndicatedFlipObjectAnyway {
            appModel.hasIndicatedFlipObjectAnyway = userHasIndicatedFlipObjectAnyway
        }

        // If the app can't flip an object and person doesn't manually override this, use the same segment and add additional orbits to it.
        if !appModel.isObjectFlippable && !appModel.hasIndicatedFlipObjectAnyway {
            session.beginNewScanPass()
        } else {
            session.beginNewScanPassAfterFlip()
            appModel.isObjectFlipped = true
        }
        showOnboardingView = false
        appModel.orbit = appModel.orbit.next()
    }

    private func transition(with input: OnboardingUserInput) {
        do {
            try onboardingStateMachine.enter(input)
            reloadData()
        } catch {
            logger.log("Could not move to new state in User Guide state machine")
        }
    }
}

private struct CreateButton: View {
    @Environment(AppDataModel.self) var appModel
    let buttonLabel: String
    var buttonLabelColor: Color = Color.white
    var buttonBackgroundColor: Color = Color.blue
    var shouldApplyBackground = false
    var showBusyIndicator = false
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(
            action: {
                logger.log("\(buttonLabel) clicked!")
                action()
            },
            label: {
                ZStack {
                    if showBusyIndicator {
                        HStack {
                            Text(buttonLabel).hidden()
                            Spacer().frame(maxWidth: 48)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(
                                    tint: shouldApplyBackground ? .white : (colorScheme == .light ? .black : .white)))
                        }
                    }
                    Text(buttonLabel)
                        .font(.headline)
                        .bold()
                        .foregroundColor(buttonLabelColor)
                        .padding(16)
                        .frame(maxWidth: shouldApplyBackground ? .infinity : nil)
                }
            })
        .frame(maxWidth: .infinity)
        .background {
            if shouldApplyBackground {
                RoundedRectangle(cornerRadius: 16.0).fill(buttonBackgroundColor)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: UIDevice.current.userInterfaceIdiom == .pad ? 380 : .infinity)
    }
}

private struct CancelButton: View {
    @Environment(AppDataModel.self) var appModel
    let buttonLabel: String
    @Binding var showOnboardingView: Bool

    var body: some View {
        Button(
            action: {
                logger.log("Cancel button clicked!")
                showOnboardingView = false
            },
            label: {
                Text(buttonLabel)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.blue)
            })
    }
}

private struct CameraToggleButton: View {
    @Binding var showShotLocations: Bool

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                logger.log("Camera toggle button clicked!")
                showShotLocations.toggle()
            }, label: {
                Image(systemName: "camera.viewfinder")
                    .font(.title)
                    .foregroundColor(.blue)
            })
            .padding(.all, 5)
            .background(.ultraThinMaterial.opacity(showShotLocations ? 1 : 0))
            .cornerRadius(15)

            Text("Show capture positions")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}
