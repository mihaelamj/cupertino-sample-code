/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller used to display the diagnosis keys stored in the local development Server.
*/

import UIKit
import CoreImage
import AVFoundation

class DeveloperDiagnosisKeysViewController: UITableViewController {
    
    var observers = [NSObjectProtocol]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        observers.append(Server.shared.$diagnosisKeys.addObserver { [unowned self] in
            self.updateTableView(animated: true)
        })
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    enum Section: Int {
        case diagnosisKeys
    }
    
    enum Item: Hashable {
        case diagnosisKeyPlaceholder
        case diagnosisKey(index: Int)
    }
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {}
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = DataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
            switch item {
            case .diagnosisKeyPlaceholder:
                return tableView.dequeueReusableCell(withIdentifier: "DiagnosisKeyPlaceholder", for: indexPath)
            case let .diagnosisKey(index):
                let cell = tableView.dequeueReusableCell(withIdentifier: "DiagnosisKey", for: indexPath)
                let diagnosisKey = Server.shared.diagnosisKeys[index]
                cell.textLabel!.text = diagnosisKey.keyData.reduce("") { $0 + String(format: "%02x", $1) }
                cell.detailTextLabel!.text = String(diagnosisKey.rollingStartNumber)
                return cell
            }
        })
        dataSource.defaultRowAnimation = .fade
        updateTableView(animated: false)
    }
    
    func updateTableView(animated: Bool) {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        snapshot.appendSections([.diagnosisKeys])
        let diagnosisKeys = Server.shared.diagnosisKeys
        if diagnosisKeys.isEmpty {
            snapshot.appendItems([.diagnosisKeyPlaceholder], toSection: .diagnosisKeys)
        } else {
            snapshot.appendItems(diagnosisKeys.enumerated().map { .diagnosisKey(index: $0.offset) }, toSection: .diagnosisKeys)
        }
        dataSource.apply(snapshot, animatingDifferences: tableView.window != nil ? animated : false)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return dataSource.itemIdentifier(for: indexPath)! != .diagnosisKeyPlaceholder
    }

    @IBSegueAction func showQRCode(_ coder: NSCoder) -> DeveloperQRCodeViewController? {
        return DeveloperQRCodeViewController(diagnosisKey: Server.shared.diagnosisKeys[tableView.indexPathForSelectedRow!.row], coder: coder)
    }
}

class DeveloperQRCodeViewController: UIViewController {
    
    let diagnosisKey: CodableDiagnosisKey
    
    init?(diagnosisKey: CodableDiagnosisKey, coder: NSCoder) {
        self.diagnosisKey = diagnosisKey
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let data = try! JSONEncoder().encode(diagnosisKey)
        let filter = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": data])!
        imageView.image = UIImage(ciImage: filter.outputImage!.transformed(by: .init(scaleX: 8.0, y: 8.0)))
    }
    
    @IBAction func tap() {
        dismiss(animated: true, completion: nil)
    }
}

class DeveloperQRCodeScannerViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scannerView = view as! DeveloperQRCodeScannerView
        scannerView.dataHandler = { data in
            if let diagnosisKey = try? JSONDecoder().decode(CodableDiagnosisKey.self, from: data) {
                if !Server.shared.diagnosisKeys.contains(diagnosisKey) {
                    Server.shared.diagnosisKeys.append(diagnosisKey)
                }
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    @IBAction func tap() {
        dismiss(animated: true, completion: nil)
    }
}

class DeveloperQRCodeScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    
    var dataHandler: ((Data) -> Void)?
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let captureSession = AVCaptureSession()
        
        let captureDevice = AVCaptureDevice.default(for: .video)!
        do {
            captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
        } catch {
            print("Unable to add capture device:\(error)")
        }
        
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.metadataObjectTypes = [.qr]
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        
        captureSession.startRunning()
        
        let videoPreviewLayer = layer as! AVCaptureVideoPreviewLayer
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.session = captureSession
    }
    
    func metadataOutput(_ captureOutput: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let string = metadataObject.stringValue,
            let data = string.data(using: .utf8) {
            dataHandler?(data)
        }
    }
}
