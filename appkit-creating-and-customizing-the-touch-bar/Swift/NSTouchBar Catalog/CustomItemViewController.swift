/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSButtons in an NSTouchBar instance.
*/

import Cocoa

class CustomItemViewController: NSViewController {
    
    @IBOutlet weak var sizeConstraint: NSButton!
    @IBOutlet weak var useCustomColor: NSButton!
    
    @IBOutlet weak var button3WidthConstraint: NSLayoutConstraint!
    var originalButton3Width: CGFloat = 0

    // MARK: - Action Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalButton3Width = button3WidthConstraint.constant
    }
    
    @IBAction func customize(_ sender: AnyObject) {
        guard let touchBar = touchBar else { return }
        
        for itemIdentifier in touchBar.itemIdentifiers {
            
            guard let item = touchBar.item(forIdentifier: itemIdentifier) as? NSCustomTouchBarItem,
                let button = item.view as? NSButton else { continue }
            
            let textRange = NSRange(location: 0, length: button.title.count)
            let titleColor = useCustomColor.state == NSControl.StateValue.on ? NSColor.black : NSColor.white
            let newTitle = NSMutableAttributedString(string: button.title)
            newTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: titleColor, range: textRange)
            newTitle.addAttribute(NSAttributedString.Key.font, value: button.font!, range: textRange)
            newTitle.setAlignment(.center, range: textRange)
            button.attributedTitle = newTitle
            
            button.bezelColor = useCustomColor.state == NSControl.StateValue.on ? NSColor.systemYellow : nil
        }
        
        if sizeConstraint.state == NSControl.StateValue.on {
            /** If the size constraint checkbox is in a selected state, set the button's width, larger with the image hugging the title.
                Set the layout constraint on this button so that it's 200 pixels wide.
             */
            button3WidthConstraint.constant = 200
        } else {
            button3WidthConstraint.constant = self.originalButton3Width
        }
    }
    
    @IBAction func buttonAction(_ sender: AnyObject) {
        if let button = sender as? NSButton {
            print("\(#function): button with title \"\(button.title)\" is tapped")
        }
    }
}

