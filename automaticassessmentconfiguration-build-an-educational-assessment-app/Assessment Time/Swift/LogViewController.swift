/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The log view controller.
*/
import Cocoa

// Add the @objc attribute to be able to share a storyboard between Swift and Objective-C.
@objc(LogViewController)
class LogViewController: NSViewController {

    @IBOutlet var logTextView: NSTextView!
    var observer: Any?
    var formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the formatter.
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        
        // Set up the view.
        observer = NotificationCenter.default.addObserver(forName: NSNotification.Name("LogThis"), object: nil, queue: nil) { note in
            if let message = note.object as? String {
                self.log(message)
            }
        }
    }
    override func viewWillAppear() {
        super.viewWillAppear()
        
        logTextView.window?.setFrameAutosaveName("LogWindow")
        log("Log view loaded.")
    }
    
    // Write the current date and a message to the log and to the console.
    func log(_ message: String ) {
        
        let now = formatter.string( from: Date() )

        let messageWithDate = "\(now): \(message)\n"
        DispatchQueue.main.async {
            self.logTextView.textStorage?.append( NSAttributedString(string: messageWithDate))
            self.logTextView.scrollToEndOfDocument(nil)
        }
        // Also log it to the console.
        NSLog("%@", message)
    }
}
