/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller for the main view of the app.
*/

import UIKit
import SceneKit
import ARKit
import Vision
import PencilKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /// Concurrent queue to be used for model predictions
    let predictionQueue = DispatchQueue(label: "predictionQueue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .inherit,
                                        target: nil)

    /// The ARSceneView
    @IBOutlet var sceneView: ARSCNView!

    /// Label used to display any relevant information to the user
    /// This can be the model name, the predicted dice, the recognized digit, ...
    @IBOutlet weak var infoLabel: UILabel!

    /// Layer used to host detectionOverlay layer
    var rootLayer: CALayer!
    /// The detection overlay layer used to render bounding boxes
    var detectionOverlay: CALayer!

    /// Whether the current frame should be skipped (in terms of model predictions)
    var shouldSkipFrame = 0
    /// How often (in terms of camera frames) should the app run predictions
    let predictEvery = 3

    /// Vision request for the detection model
    var diceDetectionRequest: VNCoreMLRequest!

    /// Flag used to decide whether to draw bounding boxes for detected objects
    var showBoxes = true {
        didSet {
            if !showBoxes {
                removeBoxes()
            }
        }
    }

    /// Size of the camera image buffer (used for overlaying boxes)
    var bufferSize: CGSize! {
        didSet {
            if bufferSize != nil {
                if oldValue == nil {
                    setupLayers()
                } else if oldValue != bufferSize {
                    updateDetectionOverlaySize()
                }
            }

        }
    }

    /// The last known image orientation
    /// When the image orientation changes, the buffer size used for rendering boxes needs to be adjusted
    var lastOrientation: CGImagePropertyOrientation = .right

    /// Last known dice values
    var lastDiceValues = [Int]()
    /// last observed dice
    var lastObservations = [VNRecognizedObjectObservation]()

    enum RollState {
        case other
        case started
        case ended
    }

    /// Current state of the dice roll
    var rollState = RollState.other

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self

        // Set the session's delegate
        sceneView.session.delegate = self

        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene

        // Get the root layer so in order to draw rectangles
        rootLayer = sceneView.layer

        // Load the detection models
        /// - Tag: SetupVisionRequest
        guard let mlModel = try? DiceDetector(configuration: .init()).model,
              let detector = try? VNCoreMLModel(for: mlModel) else {
            print("Failed to load detector!")
            return
        }

        // Use a threshold provider to specify custom thresholds for the object detector.
        detector.featureProvider = ThresholdProvider()

        diceDetectionRequest = VNCoreMLRequest(model: detector) { [weak self] request, error in
            self?.detectionRequestHandler(request: request, error: error)
        }
        // .scaleFill results in a slight skew but the model was trained accordingly
        // see https://developer.apple.com/documentation/vision/vnimagecropandscaleoption for more information
        diceDetectionRequest.imageCropAndScaleOption = .scaleFill
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Disable dimming for demo
        UIApplication.shared.isIdleTimerDisabled = true

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    func bounds(for observation: VNRecognizedObjectObservation) -> CGRect {
        let boundingBox = observation.boundingBox
        // Coordinate system is like macOS, origin is on bottom-left and not top-left

        // The resulting bounding box from the prediction is a normalized bounding box with coordinates from bottom left
        // It needs to be flipped along the y axis
        let fixedBoundingBox = CGRect(x: boundingBox.origin.x,
                                      y: 1.0 - boundingBox.origin.y - boundingBox.height,
                                      width: boundingBox.width,
                                      height: boundingBox.height)

        // Return a flipped and scaled rectangle corresponding to the coordinates in the sceneView
        return VNImageRectForNormalizedRect(fixedBoundingBox, Int(sceneView.frame.width), Int(sceneView.frame.height))
    }

    // MARK: - Vision Callbacks

    /// Handles results from the detection requests
    ///
    /// - parameters:
    ///     - request: The VNRequest that has been processed
    ///     - error: A potential error that may have occurred
    func detectionRequestHandler(request: VNRequest, error: Error?) {
        // Perform several error checks before proceeding
        if let error = error {
            print("An error occurred with the vision request: \(error.localizedDescription)")
            return
        }
        guard let request = request as? VNCoreMLRequest else {
            print("Vision request is not a VNCoreMLRequest")
            return
        }
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            print("Request did not return recognized objects: \(request.results?.debugDescription ?? "[No results]")")
            return
        }

        guard !observations.isEmpty else {
            removeBoxes()
            if !lastObservations.isEmpty {
                DispatchQueue.main.async {
                    self.infoLabel.text = ""
                }
            }
            lastObservations = []
            lastDiceValues = []
            // Since there are no detected dice, the roll is in .other state
            rollState = .other
            return
        }

        if showBoxes && rollState != .ended {
            drawBoxes(observations: observations)
        }

        // Since there are dice, the roll is either in the .started or .ended state
        rollState = hasRollEnded(observations: observations) ? .ended : .started

        if rollState == .ended {
            /// - Tag : SortingDiceObservations
            var sortableDiceValues = [(value: Int, xPosition: CGFloat)]()

            for observation in observations {
                // Select only the label with the highest confidence.
                guard let topLabelObservation = observation.labels.first else {
                    print("Object observation has no labels")
                    continue
                }

                if let intValue = Int(topLabelObservation.identifier) {
                    sortableDiceValues.append((value: intValue, xPosition: observation.boundingBox.midX))
                }
            }

            let diceValues = sortableDiceValues.sorted { $0.xPosition < $1.xPosition }.map { $0.value }

            DispatchQueue.main.async {
                self.infoLabel.text = "\(diceValues)"
            }
        }
    }

    /// - Tag: hasRollEnded
    /// Determines if a roll has ended with the current dice values O(n^2)
    ///
    /// - parameter observations: The object detection observations from the model
    /// - returns: True if the roll has ended
    func hasRollEnded(observations: [VNRecognizedObjectObservation]) -> Bool {
        // First check if same number of dice were detected
        if lastObservations.count != observations.count {
            lastObservations = observations
            return false
        }
        var matches = 0
        for newObservation in observations {
            for oldObservation in lastObservations {
                // If the labels don't match, skip it
                // Or if the IOU is less than 85%, consider this box different
                // Either it's a different die or the same die has moved
                if newObservation.labels.first?.identifier == oldObservation.labels.first?.identifier &&
                    intersectionOverUnion(oldObservation.boundingBox, newObservation.boundingBox) > 0.85 {
                    matches += 1
                }
            }
        }
        lastObservations = observations
        return matches == observations.count
    }
}
