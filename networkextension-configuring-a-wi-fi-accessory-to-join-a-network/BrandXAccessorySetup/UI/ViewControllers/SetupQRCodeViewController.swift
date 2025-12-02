/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller to present a modal to scan a QR code.
*/

import UIKit

final class SetupQRCodeViewController: SetupBaseViewController {
    
    // MARK: - @IBOutlet variables
    
    @IBOutlet private weak var nextAction: UIButton!
    @IBOutlet private weak var instruction: UILabel!
    
    // MARK: - Public Variables
    
    public var didScanQRCode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Scan QR code"
    }
    
    // MARK: - IBActions
    
    @IBAction func scanQRCode() {
        
        if didScanQRCode {
            if let networkInfoVC = storyBoard.instantiateViewController(identifier: networkInfoVCStoryBoardIdentifier)
                as? SetupNetworkInfoViewController {
                self.navigationController?.pushViewController(networkInfoVC, animated: true)
            }
            return
        }
        let qrScanningViewController = QRScanningViewController()
        qrScanningViewController.delegate = self
        self.modalPresentationStyle = .fullScreen
        self.present(qrScanningViewController, animated: true, completion: nil)
    }
}

// MARK: - QRScanningDelegate Methods

extension SetupQRCodeViewController: QRScanningDelegate {
    
    func didDetectQRCode(qrScanningViewController: QRScanningViewController,
                         for accessoryNetwork: AccessoryNetwork) {
        instruction.text = "QR code scanned and network information captured"
        nextAction.setTitle("Next", for: .normal)
        didScanQRCode = true
    }
}
