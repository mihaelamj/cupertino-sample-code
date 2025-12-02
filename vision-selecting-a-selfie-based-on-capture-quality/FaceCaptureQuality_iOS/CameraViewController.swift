/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the view controller responsible for capturing images and processing them with Vision to get face-capture quality metric.
*/

import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {

    var previewLayer: AVCaptureVideoPreviewLayer?
    var observationsOverlay = UIView()
    var isCapturingFaces = false
    let savedFacesDataSource = SavedFacesDataSource()
    let feedbackGenerator = UISelectionFeedbackGenerator()
    
    func performVisionRequests(on pixelBuffer: CVPixelBuffer) {
        var requestOptions = [VNImageOption: Any]()
        if let cameraIntrinsicData = CMGetAttachment(pixelBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        // This sample code supports portrait device orientaion only.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: requestOptions)
        let faceDetectionRequest = VNDetectFaceCaptureQualityRequest()
        do {
            try handler.perform([faceDetectionRequest])
            guard let faceObservations = faceDetectionRequest.results as? [VNFaceObservation] else {
                return
            }
            displayFaceObservations(faceObservations)
            if isCapturingFaces {
                saveFaceObservations(faceObservations, in: pixelBuffer)
            }
        } catch {
            print("Vision error: \(error.localizedDescription)")
        }
    }
    
    var reusableFaceObservationOverlayViews: [FaceObservationOverlayView] {
        if let existingViews = observationsOverlay.subviews as? [FaceObservationOverlayView] {
            return existingViews
        } else {
            return [FaceObservationOverlayView]()
        }
    }
    
    func displayFaceObservations(_ faceObservations: [VNFaceObservation]) {
        let overlay = observationsOverlay
        DispatchQueue.main.async {
            var reusableViews = self.reusableFaceObservationOverlayViews
            for observation in faceObservations {
                // Reuse existing observation view if there is one.
                if let existingView = reusableViews.popLast() {
                    existingView.faceObservation = observation
                } else {
                    let newView = FaceObservationOverlayView(faceObservation: observation)
                    overlay.addSubview(newView)
                }
            }
            // Remove previously existing views that weren't reused.
            for view in reusableViews {
                view.removeFromSuperview()
            }
        }
    }
    
    func saveFaceObservations(_ faceObservations: [VNFaceObservation], in pixelBuffer: CVPixelBuffer) {
        let ciImg = CIImage(cvPixelBuffer: pixelBuffer)
        let imgWidth = ciImg.extent.width
        let imgHeight = ciImg.extent.height
        let ciCtx = CIContext()
        for observation in faceObservations {
            let faceBox = observation.boundingBox
            // Vision coordinates are normalized and have lower-left origin.
            // Also, pixel buffer has .leftMirrored orientation.
            let cropRect = CGRect(x: (1 - faceBox.minY - faceBox.height) * imgWidth,
                                  y: (1 - faceBox.minX - faceBox.width) * imgHeight,
                                  width: faceBox.height * imgWidth,
                                  height: faceBox.width * imgHeight)
            if let cgImg = ciCtx.createCGImage(ciImg, from: cropRect) {
                let faceCrop = UIImage(cgImage: cgImg, scale: 1, orientation: .leftMirrored)
                let identifier = observation.uuid.uuidString
                if let score = observation.faceCaptureQuality, let jpegData = faceCrop.jpegData(compressionQuality: 1) {
                    savedFacesDataSource.saveFaceCrop(jpegData, faceId: identifier, qualityScore: score)
                    DispatchQueue.main.async { [weak self] in
                        self?.feedbackGenerator.selectionChanged()
                    }
                    updateSavedFacesCount()
                }
            }
        }
    }
    
    func updateSavedFacesCount() {
        let facesCount = savedFacesDataSource.savedFaces.count
        let format = NSLocalizedString("FacesSavedCount", comment: "Number of saved faces")
        let title = String(format: format, facesCount)
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.title = title
        }
    }
    
    @IBAction func clearSavedFaces(_ sender: Any) {
        savedFacesDataSource.removePreviouslySavedFaces()
        updateSavedFacesCount()
    }
    
    @IBAction func startCapture(_ sender: Any) {
        isCapturingFaces = true
    }
    
    @IBAction func stopCapture(_ sender: Any) {
        isCapturingFaces = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowSavedFacesSegue", let savedFacesVC = segue.destination as? SavedFacesViewController else {
            return
        }
        savedFacesVC.savedFaces = savedFacesDataSource.savedFaces
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let newSession = makeAVCaptureSession() else {
            return
        }
        view.insertSubview(observationsOverlay, at: 0)
        let previewLayer = AVCaptureVideoPreviewLayer(session: newSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
        updateSavedFacesCount()
        feedbackGenerator.prepare()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        DispatchQueue.global().async { [weak self] in
            self?.previewLayer?.session?.startRunning()
        }
        view.setNeedsLayout()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        previewLayer?.session?.stopRunning()
        super.viewDidDisappear(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let previewLayer = self.previewLayer else {
            return
        }
        // Preview layer's frame should match view bounds.
        previewLayer.frame = view.bounds
        // Overlay view's frame should match video rect bounds.
        let videoRect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        let layerRect = previewLayer.layerRectConverted(fromMetadataOutputRect: videoRect)
        observationsOverlay.frame = layerRect
    }
    
    func makeAVCaptureSession() -> AVCaptureSession? {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Error locating AVCaptureDevice.")
            return nil
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Error creating AVCaptureDeviceInput.")
            return nil
        }
        
        let session = AVCaptureSession()
        guard session.canAddInput(input) else {
            print("Can not add AVCaptureDeviceInput.")
            return nil
        }
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        guard session.canAddOutput(output) else {
            print("Can not add AVCaptureVideoDataOutput.")
            return nil
        }
        session.addOutput(output)
        return session
    }
    
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        performVisionRequests(on: pixelBuffer)
    }
}
