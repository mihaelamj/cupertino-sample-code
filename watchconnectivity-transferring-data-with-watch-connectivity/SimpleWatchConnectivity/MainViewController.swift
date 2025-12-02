/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller of the iOS app.
*/

import UIKit
import WatchConnectivity

class MainViewController: UIViewController {
        
    @IBOutlet weak var reachableLabel: UILabel!
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var tablePlaceholderView: UIView!
    
    // The app logs the file transfer progress on the log view, so it needs to
    // observe the file transfer progress.
    //
    private let fileTransferObservers = FileTransferObservers()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).activationDidComplete(_:)),
            name: .activationDidComplete, object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).reachabilityDidChange(_:)),
            name: .reachabilityDidChange, object: nil
        )
    }
    
    // Implement the round corners on the top.
    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let layer = CALayer()
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize(width: 0, height: 1)
        
        // Make sure the shadow is outside of the bottom of the screen.
        //
        var rect = self.tableContainerView.bounds
        
        if #available(iOS 11.0, *) {
            rect.size.height += view.window!.safeAreaInsets.bottom
        }
        
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: [.topRight, .topLeft],
                                cornerRadii: CGSize(width: 10, height: 10))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.white.cgColor
        
        layer.addSublayer(shapeLayer)
        
        tableContainerView.layer.addSublayer(layer)
        tablePlaceholderView.layer.zPosition = layer.zPosition + 1
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Append the message to the end of the text view, and make sure it's visible.
    //
    private func log(_ message: String) {
        logView.text = logView.text! + "\n\n" + message
        logView.scrollRangeToVisible(NSRange(location: logView.text.count, length: 1))
    }
    
    private func updateReachabilityColor() {
        // WCSession.isReachable triggers a warning if the session isn't in .activated state.
        //
        var isReachable = false
        if WCSession.default.activationState == .activated {
            isReachable = WCSession.default.isReachable
        }
        reachableLabel.backgroundColor = isReachable ? .green : .red
    }
    
    // .activationDidComplete notification handler.
    //
    @objc
    func activationDidComplete(_ notification: Notification) {
        updateReachabilityColor()
    }
    
    // .reachabilityDidChange notification handler.
    //
    @objc
    func reachabilityDidChange(_ notification: Notification) {
        updateReachabilityColor()
    }

    @IBAction func clear(_ sender: UIButton) {
        logView.text = ""
    }
    
    // .dataDidFlow notification handler.
    // Update the UI using the userInfo dictionary of the notification.
    //
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? CommandStatus else { return }
        
        defer { noteLabel.isHidden = logView.text.isEmpty ? false: true }
        
        // If an error occurs, show the error message and return.
        //
        if let errorMessage = commandStatus.errorMessage {
            log("! \(commandStatus.command.rawValue)...\(errorMessage)")
            return
        }
        
        guard let timedColor = commandStatus.timedColor else { return }
        
        log("#\(commandStatus.command.rawValue)...\n\(commandStatus.phrase.rawValue) at \(timedColor.timeStamp)")
        
        if let fileURL = commandStatus.file?.fileURL {
            
            if fileURL.pathExtension == "log",
                let content = try? String(contentsOf: fileURL, encoding: .utf8), !content.isEmpty {
                log("\(fileURL.lastPathComponent)\n\(content)")
            } else {
                log("\(fileURL.lastPathComponent)\n")
            }
        }
        
        if let fileTransfer = commandStatus.fileTransfer, commandStatus.command == .transferFile {

            if commandStatus.phrase == .finished {
                fileTransferObservers.unobserve(fileTransfer)
                
            } else if commandStatus.phrase == .transferring {
                fileTransferObservers.observe(fileTransfer) { _ in
                    self.logProgress(for: fileTransfer)
                }
            }
        }
    }
    
    // Log the file transfer progress.
    //
    private func logProgress(for fileTransfer: WCSessionFileTransfer) {
        DispatchQueue.main.async {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            let timeString = dateFormatter.string(from: Date())
            let fileName = fileTransfer.file.fileURL.lastPathComponent
            
            let progress = fileTransfer.progress.localizedDescription ?? "No progress"
            self.log("- \(fileName): \(progress) at \(timeString)")
        }
    }
}
