/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to provide the capture session that scans the QR code.
*/
import AVFoundation
import UIKit

final class QRScanningViewController: UIViewController {
    
    // MARK: - Public Variables
    
    public weak var delegate: QRScanningDelegate?
    
    // MARK: - Private Variables
    
    private var qrCaptureSession = AVCaptureSession()
    private var qrCaptureLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - ViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let qrCapturedMetadataOutput = AVCaptureMetadataOutput()
        let videoDeviceInput: AVCaptureDeviceInput
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            // Make sure the user knows when QR code-scanning setup fails.
            didFailToStartScanningSession()
            return
        }
        
        // Set up capture input.
        if qrCaptureSession.canAddInput(videoDeviceInput) {
            qrCaptureSession.addInput(videoDeviceInput)
        } else {
            // Make sure the user knows when QR code-scanning setup fails.
            didFailToStartScanningSession()
            return
        }
        
        // Set up metadata capture output.
        if qrCaptureSession.canAddOutput(qrCapturedMetadataOutput) {
            qrCaptureSession.addOutput(qrCapturedMetadataOutput)
            qrCapturedMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            qrCapturedMetadataOutput.metadataObjectTypes = [.qr]
        } else {
            // Make sure the user knows when QR code-scanning setup fails.
            didFailToStartScanningSession()
            return
        }
        
        // Set up and start the capture session with respect to the current orientation.
        let captureLayer = AVCaptureVideoPreviewLayer(session: qrCaptureSession)
        qrCaptureLayer = captureLayer
        captureLayer.frame = view.layer.bounds
        captureLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(captureLayer)
        qrCaptureSession.startRunning()
        
        // Build a Cancel button that sits on top of the view to dismiss the capture session, if necessary.
        let cancelButton = UIButton(frame: CGRect(x: 5, y: 10, width: 100, height: 38))
        cancelButton.backgroundColor = .clear
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonAction), for: .touchUpInside)
        view.addSubview(cancelButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !qrCaptureSession.isRunning {
            qrCaptureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if qrCaptureSession.isRunning {
            qrCaptureSession.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let previewLayerConnection = self.qrCaptureLayer?.connection, previewLayerConnection.isVideoOrientationSupported,
           let sceneOrientation = self.view.window?.windowScene?.interfaceOrientation {
            
            var orientation: AVCaptureVideoOrientation = .portrait
            switch sceneOrientation {
            case .portrait:
                orientation = .portrait
            case .landscapeRight:
                orientation = .landscapeRight
            case .landscapeLeft:
                orientation = .landscapeLeft
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
            case .unknown:
                orientation = .portrait
            @unknown default:
                orientation = .portrait
            }
            
            previewLayerConnection.videoOrientation = orientation
            qrCaptureLayer?.frame = self.view.bounds
        }
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - IBActions
    
    @objc
    func cancelButtonAction(sender: UIButton!) {
        didDismissViewController()
    }
    
    // MARK: - Private Instance Methods
    
    /// Notify the user that the device doesn’t support scanning.
    private func didFailToStartScanningSession(message: String = "Device cannot scan for QR code") {
        let alertController = UIAlertController(title: "QR Scanning",
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak self]  (action) in
            self?.didDismissViewController()
        }))
        present(alertController, animated: true)
    }
    
    // Actually dismiss the viewcontroller.
    private func didDismissViewController() {
        dismiss(animated: true)
    }
    
    // Set the actual parsed data in DeviceNetworkManager.
    private func didFindDataInQRCode(qrCodeString: String) -> AccessoryNetwork? {
        do {
            let accessoryNetwork = try AccessoryNetwork(with: qrCodeString)
            DeviceNetworkManager.shared.accessoryNetwork = accessoryNetwork
            
            return accessoryNetwork
        } catch AccessoryNetwork.ParserError.networkCredentialError(let message),
                AccessoryNetwork.ParserError.schemeError(let message),
                AccessoryNetwork.ParserError.hostError(let message),
                AccessoryNetwork.ParserError.tlsError(let message),
                AccessoryNetwork.ParserError.badDataError(let message) {
            didFailToStartScanningSession(message: message.localizedDescription)
        } catch {
            didFailToStartScanningSession(message: error.localizedDescription)
        }
        // Handle the nil path with the didFailToStartScanningSession error handling above.
        return nil
    }
    
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate Methods

extension QRScanningViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    /// The Delegate callback when AVCaptureMetadataOutput has output to deliver (the QR code data).
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        qrCaptureSession.stopRunning()
        
        // The device found the QR data, so stop the capture, parse the data, and dismiss the view controller.
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            guard let accessoryNetwork = didFindDataInQRCode(qrCodeString: stringValue) else { return }
            self.delegate?.didDetectQRCode(qrScanningViewController: self, for: accessoryNetwork)
            didDismissViewController()
        }
    }
    
}

/// QRScanningDelegate notifies a class that AccessoryNetwork data is available.
protocol QRScanningDelegate: AnyObject {
    func didDetectQRCode(qrScanningViewController: QRScanningViewController,
                         for accessoryNetwork: AccessoryNetwork)
}
