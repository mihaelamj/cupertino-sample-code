/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's view controller that handles the trajectory analysis.
*/

import UIKit
import AVFoundation
import Vision

class ContentAnalysisViewController: UIViewController,
                                     AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - Static Properties
    static let segueDestinationId = "ShowAnalysisView"
    
    // MARK: - IBOutlets
    @IBOutlet var closeButton: UIButton!
    
    // MARK: - IBActions
    @IBAction func closeRootViewTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Public Properties
    var recordedVideoSource: AVAsset?
    
    // MARK: - Private Properties
    private var cameraViewController: CameraViewController!
    private var trajectoryView = TrajectoryView()
    private var setupComplete = false
    private var detectTrajectoryRequest: VNDetectTrajectoriesRequest!
    
    // A dictionary that stores all trajectories.
    private var trajectoryDictionary: [String: [VNPoint]] = [:]
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        recordedVideoSource = nil
        detectTrajectoryRequest = nil
    }
    
    // MARK: - Public Methods
    
    // The sample app calls this when the camera view delegate begins reading
    // frames of a video buffer.
    func setUpDetectTrajectoriesRequestWithMaxDimension() {
        
        guard setupComplete == false else {
            return
        }
        
        /**
         Define what the sample app looks for, and how to handle the output trajectories.
         Setting the frame time spacing to (10, 600) so the framework looks for trajectories after each 1/60 second of video.
         Setting the trajectory length to 6 so the framework returns trajectories of a length of 6 or greater.
         Use a shorter length for real-time apps, and use longer lengths to observe finer and longer curves.
         */
        detectTrajectoryRequest = VNDetectTrajectoriesRequest(frameAnalysisSpacing: CMTime(value: 10, timescale: 600),
                                                              trajectoryLength: 6) { [weak self] (request: VNRequest, error: Error?) -> Void in
            
            guard let results = request.results as? [VNTrajectoryObservation] else {
                return
            }
            
            DispatchQueue.main.async {
                self?.processTrajectoryObservation(results: results)
            }
            
        }
        setupComplete = true
        
    }
    
    // MARK: - Private Methods
    
    private func processTrajectoryObservation(results: [VNTrajectoryObservation]) {
        
        // Clear and reset the trajectory view if there are no trajectories.
        guard !results.isEmpty else {
            trajectoryView.resetPath()
            return
        }
        print("Total trajectory count: \(results.count)")
        
        for trajectory in results {
            // Filter the trajectory.
            if filterParabola(trajectory: trajectory) {
                // Verify and correct an incomplete path.
                trajectoryView.points = correctTrajectoryPath(trajectoryToCorrect: trajectory)
                
                // Display a transition.
                trajectoryView.performTransition(.fadeIn, duration: 0.05)
                
                // Determine the size of the moving object that the app tracks.
                print("The object's moving average radius: \(trajectory.movingAverageRadius)")
            }
        }
    
    }
    
    private func filterParabola(trajectory: VNTrajectoryObservation) -> Bool {
        
        if trajectoryDictionary[trajectory.uuid.uuidString] == nil {
            // Add the new trajectories to the dictionary.
            trajectoryDictionary[trajectory.uuid.uuidString] = trajectory.projectedPoints
        } else {
            // Increase the points on the existing trajectory.
            // The framework returns the last five projected points, so check whether a trajectory is
            // increasing, and update it.
            if trajectoryDictionary[trajectory.uuid.uuidString]!.last != trajectory.projectedPoints[4] {
                trajectoryDictionary[trajectory.uuid.uuidString]!.append(trajectory.projectedPoints[4])
            }
        }
        
        /**
         Filter the trajectory with the following conditions:
            - The trajectory moves from left to right.
            - The trajectory starts in the first half of the region of interest.
            - The trajectory length increases to 8.
            - The trajectory contains a parabolic equation constant a, less than or equal to 0, and implies there
                are either straight lines or downward-facing lines.
            - The trajectory confidence is greater than 0.9.
         
         Add additional filters based on trajectory speed, location, and properties.
         */
        if trajectoryDictionary[trajectory.uuid.uuidString]!.first!.x < trajectoryDictionary[trajectory.uuid.uuidString]!.last!.x
            && trajectoryDictionary[trajectory.uuid.uuidString]!.first!.x < 0.5
            && trajectoryDictionary[trajectory.uuid.uuidString]!.count >= 8
            && trajectory.equationCoefficients[0] <= 0
            && trajectory.confidence > 0.9 {
            return true
        } else {
            return false
        }
        
    }
    
    private func correctTrajectoryPath(trajectoryToCorrect: VNTrajectoryObservation) -> [VNPoint] {
    
        guard var basePoints = trajectoryDictionary[trajectoryToCorrect.uuid.uuidString],
              var basePointX = basePoints.first?.x else {
            return []
        }
        
        /**
         This is inside region-of-interest space where both x and y range between 0.0 and 1.0.
         If a left-to-right moving trajectory begins too far from a fixed region, extrapolate it back
         to that region using the available quadratic equation coefficients.
         */
        if basePointX > 0.1 {
            
            // Compute the initial trajectory location points based on the average
            // change in the x direction of the first five points.
            var sum = 0.0
            for i in 0..<5 {
                sum = sum + basePoints[i + 1].x - basePoints[i].x
            }
            let averageDifferenceInX = sum / 5.0
        
            while basePointX > 0.1 {
                let nextXValue = basePointX - averageDifferenceInX
                let aXX = Double(trajectoryToCorrect.equationCoefficients[0]) * nextXValue * nextXValue
                let bX = Double(trajectoryToCorrect.equationCoefficients[1]) * nextXValue
                let c = Double(trajectoryToCorrect.equationCoefficients[2])
                
                let nextYValue = aXX + bX + c
                if nextYValue > 0 {
                    // Insert values into the trajectory path present in the positive Cartesian space.
                    basePoints.insert(VNPoint(x: nextXValue, y: nextYValue), at: 0)
                }
                basePointX = nextXValue
            }
            // Update the dictionary with the corrected path.
            trajectoryDictionary[trajectoryToCorrect.uuid.uuidString] = basePoints
            
        }
        return basePoints
        
    }
    
    private func configureView() {
        
        // Set up the video layers.
        cameraViewController = CameraViewController()
        cameraViewController.view.frame = view.bounds
        addChild(cameraViewController)
        cameraViewController.beginAppearanceTransition(true, animated: true)
        view.addSubview(cameraViewController.view)
        cameraViewController.endAppearanceTransition()
        cameraViewController.didMove(toParent: self)
        
        do {
            if recordedVideoSource != nil {
                // Start reading the video.
                cameraViewController.startReadingAsset(recordedVideoSource!)
            } else {
                // Start live camera capture.
                try cameraViewController.setupAVSession()
            }
        } catch {
            AppError.display(error, inViewController: self)
        }
        
        cameraViewController.outputDelegate = self
        
        // Add a custom trajectory view for overlaying trajectories.
        view.addSubview(trajectoryView)
        view.addSubview(closeButton)
        view.bringSubviewToFront(closeButton)
        
    }
    
}

extension ContentAnalysisViewController: CameraViewControllerOutputDelegate {
    
    func cameraViewController(_ controller: CameraViewController,
                              didReceiveBuffer buffer: CMSampleBuffer,
                              orientation: CGImagePropertyOrientation) {
        
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: buffer,
                                                  orientation: orientation,
                                                  options: [:])
        
        let normalizedFrame = CGRect(x: 0.25, y: 0.4, width: 0.65, height: 0.5)
        DispatchQueue.main.async {
            // Get the frame of the rendered view.
            self.trajectoryView.frame = controller.viewRectForVisionRect(normalizedFrame)
        }
        
        setUpDetectTrajectoriesRequestWithMaxDimension()
        
        guard let detectTrajectoryRequest = detectTrajectoryRequest else {
            print("Failed to retrieve a trajectory request.")
            return
        }
        
        do {
            // Following optional bounds by checking for the moving average radius
            // of the trajectories the app is looking for.
            detectTrajectoryRequest.objectMinimumNormalizedRadius = 10.0 / Float(1920.0)
            detectTrajectoryRequest.objectMaximumNormalizedRadius = 30.0 / Float(1920.0)
            
            // Help manage the real-time use case to improve the precision versus delay tradeoff.
            detectTrajectoryRequest.targetFrameTime = CMTimeMake(value: 1, timescale: 60)
            
            // The region of interest where the object is moving in the normalized image space.
            detectTrajectoryRequest.regionOfInterest = normalizedFrame
            
            try visionHandler.perform([detectTrajectoryRequest])
        } catch {
            print("Failed to perform the trajectory request: \(error.localizedDescription)")
            return
        }
        
    }
    
}
