/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the view controller showing tracked content.
*/

import AVFoundation
import UIKit

class TrackingViewController: UIViewController {

    enum State {
        case tracking
        case stopped
    }
    
    @IBOutlet weak var entitySelector: UISegmentedControl!
    @IBOutlet weak var modeSelector: UISegmentedControl!
    @IBOutlet weak var clearRectsButton: UIButton!
    @IBOutlet weak var startStopButton: UIBarButtonItem!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var trackingView: TrackingImageView!
    @IBOutlet weak var trackingViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var frameCounterLabel: UILabel!
    @IBOutlet weak var frameCounterLabelBackplate: UIView!
    
    var videoAsset: AVAsset! {
        didSet {
            visionProcessor = VisionTrackerProcessor(videoAsset: videoAsset)
            visionProcessor.delegate = self
        }
    }

    private var visionProcessor: VisionTrackerProcessor!
    private var workQueue = DispatchQueue(label: "com.apple.VisionTracker", qos: .userInitiated)
    private var trackedObjectType: TrackedObjectType = .object
    private var objectsToTrack = [TrackedPolyRect]()
    private var state: State = .stopped {
        didSet {
            self.handleStateChange()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let backplateLayer = frameCounterLabelBackplate.layer
        backplateLayer.cornerRadius = backplateLayer.bounds.height / 2
        frameCounterLabelBackplate.isHidden = true
        frameCounterLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .light)
        self.handleModeSelection(modeSelector)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        workQueue.async {
            self.displayFirstVideoFrame()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        visionProcessor.cancelTracking()
        super.viewWillDisappear(animated)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func displayFirstVideoFrame() {
        do {
            let isTrackingRects = (self.trackedObjectType == .rectangle)
            try visionProcessor.readAndDisplayFirstFrame(performRectanglesDetection: isTrackingRects)
        } catch {
            self.handleError(error)
        }
    }
    
    private func startTracking() {
        do {
            try visionProcessor.performTracking(type: trackedObjectType)
        } catch {
            self.handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async {
            var title: String
            var message: String
            if let processorError = error as? VisionTrackerProcessorError {
                title = "Vision Processor Error"
                switch processorError {
                case .firstFrameReadFailed:
                    message = "Cannot read the first frame from selected video."
                case .objectTrackingFailed:
                    message = "Tracking of one or more objects failed."
                case .readerInitializationFailed:
                    message = "Cannot create a Video Reader for selected video."
                case .rectangleDetectionFailed:
                    message = "Rectagle Detector failed to detect rectangles on the first frame of selected video."
                }
            } else {
                title = "Error"
                message = error.localizedDescription
            }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func handleStateChange() {
        let newBarButton: UIBarButtonItem!
        var navBarHidden: Bool!
        var frameCounterHidden: Bool!
        switch state {
        case .stopped:
            navBarHidden = false
            frameCounterHidden = true
            // reveal settings view
            trackingViewTopConstraint.constant = 0
            entitySelector.isEnabled = true
            newBarButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(handleStartStopButton(_:)))
        case .tracking:
            navBarHidden = true
            frameCounterHidden = false
            // cover settings view
            trackingViewTopConstraint.constant = -settingsView.frame.height
            entitySelector.isEnabled = false
            newBarButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(handleStartStopButton(_:)))
        }
        self.navigationController?.setNavigationBarHidden(navBarHidden, animated: true)
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.navigationItem.rightBarButtonItem = newBarButton
            self.frameCounterLabelBackplate.isHidden = frameCounterHidden
        })
    }
    
    @IBAction func handleEntitySelection(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            trackedObjectType = .object
            navigationItem.prompt = "Drag to select objects"
            clearRectsButton.isEnabled = true
        case 1:
            trackedObjectType = .rectangle
            navigationItem.prompt = "Rectangles are detected automatically"
            clearRectsButton.isEnabled = false
        default:
            break
        }
        workQueue.async {
            self.displayFirstVideoFrame()
        }
    }
    
    @IBAction func handleModeSelection(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            visionProcessor.trackingLevel = .fast
        case 1:
            visionProcessor.trackingLevel = .accurate
        default:
            break
        }
    }
    
    @IBAction func handleClearRectsButton(_ sender: UIButton) {
        objectsToTrack.removeAll()
        workQueue.async {
            self.displayFirstVideoFrame()
        }
    }
    
    @IBAction func handleStartStopButton(_ sender: UIBarButtonItem) {
        switch state {
        case .tracking:
            // stop tracking
            self.visionProcessor.cancelTracking()
            self.state = .stopped
            workQueue.async {
                self.displayFirstVideoFrame()
            }
        case .stopped:
            // initialize processor and start tracking
            state = .tracking
            visionProcessor.objectsToTrack = objectsToTrack
            workQueue.async {
                self.startTracking()
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let locationInView = touch.location(in: trackingView)
        return trackingView.isPointWithinDrawingArea(locationInView) && self.trackedObjectType == .object
    }
    
    @IBAction func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            // Initiate object selection
            let locationInView = gestureRecognizer.location(in: trackingView)
            if trackingView.isPointWithinDrawingArea(locationInView) {
                trackingView.rubberbandingStart = locationInView // start new rubberbanding
            }
        case .changed:
            // Process resizing of the object's bounding box
            let translation = gestureRecognizer.translation(in: trackingView)
            let endPoint = trackingView.rubberbandingStart.applying(CGAffineTransform(translationX: translation.x, y: translation.y))
            guard trackingView.isPointWithinDrawingArea(endPoint) else {
                return
            }
            trackingView.rubberbandingVector = translation
            trackingView.setNeedsDisplay()
        case .ended:
            // Finish resizing of the object's boundong box
            let selectedBBox = trackingView.rubberbandingRectNormalized
            if selectedBBox.width > 0 && selectedBBox.height > 0 {
                let rectColor = TrackedObjectsPalette.color(atIndex: self.objectsToTrack.count)
                self.objectsToTrack.append(TrackedPolyRect(cgRect: selectedBBox, color: rectColor))
                
                displayFrame(nil, withAffineTransform: CGAffineTransform.identity, rects: objectsToTrack)
            }
        default:
            break
        }
    }
    
    @IBAction func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // toggle navigation bar visibility if tracking is in progress
        guard state == .tracking, gestureRecognizer.state == .ended else {
            return
        }
        guard let navController = self.navigationController else {
            return
        }
        let navBarHidden = navController.isNavigationBarHidden
        navController.setNavigationBarHidden(!navBarHidden, animated: true)
    }
    
}

extension TrackingViewController: VisionTrackerProcessorDelegate {
    func displayFrame(_ frame: CVPixelBuffer?, withAffineTransform transform: CGAffineTransform, rects: [TrackedPolyRect]?) {
        DispatchQueue.main.async {
            if let frame = frame {
                let ciImage = CIImage(cvPixelBuffer: frame).transformed(by: transform)
                let uiImage = UIImage(ciImage: ciImage)
                self.trackingView.image = uiImage
            }
            
            self.trackingView.polyRects = rects ?? (self.trackedObjectType == .object ? self.objectsToTrack : [])
            self.trackingView.rubberbandingStart = CGPoint.zero
            self.trackingView.rubberbandingVector = CGPoint.zero
            
            self.trackingView.setNeedsDisplay()
        }
    }
    
    func displayFrameCounter(_ frame: Int) {
        DispatchQueue.main.async {
            self.frameCounterLabel.text = "Frame: \(frame)"
        }
    }
    
    func didFinifshTracking() {
        workQueue.async {
            self.displayFirstVideoFrame()
        }
        DispatchQueue.main.async {
            self.state = .stopped
        }
    }
}
