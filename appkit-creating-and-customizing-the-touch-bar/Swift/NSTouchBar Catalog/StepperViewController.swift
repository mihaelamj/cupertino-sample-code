/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSStepperTouchBarItem in an NSTouchBar instance.
*/

import Cocoa

class StepperViewController: NSViewController {
    let stepper = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.stepper")
    let stepperBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.stepperBar")
    
    @IBOutlet weak var useCustomDraw: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = stepperBar
        touchBar.defaultItemIdentifiers = [stepper]
        return touchBar
    }
    
    // MARK: - Action Functions
    
    @IBAction func customize(_ sender: AnyObject) {
        // This creates a call to makeTouchBar.
        touchBar = nil
    }

}

// MARK: - NSTouchBarDelegate

extension StepperViewController: NSTouchBarDelegate {

    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case stepper:
            var stepperItem: NSStepperTouchBarItem
            
            if useCustomDraw.state == NSControl.StateValue.on {
                // Create the stepper touch bar item using a custom drawing handler.
                stepperItem = NSStepperTouchBarItem(identifier: identifier, drawingHandler: { frame, value in
                    NSGraphicsContext.saveGraphicsState()

                    // Draw the stepper value.
                    let valueStr = String(format: "%.0f", value)
                    let font = NSFont.systemFont(ofSize: 12)
                    let string = NSAttributedString(string: valueStr, attributes:
                                                        [ NSAttributedString.Key.foregroundColor: NSColor.white,
                                                          NSAttributedString.Key.font: font])
                    let valueSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                    let valueRect = string.boundingRect(with: valueSize, options: [.usesFontLeading, .usesLineFragmentOrigin])
                    string.draw(at: CGPoint(x: (frame.width - valueRect.width) / 2, y: (frame.height - valueRect.height) / 2))

                    // Adorn the stepper value.
                    let fillColor = NSColor.white
                    let path = NSBezierPath(rect: frame)
                    fillColor.set()
                    path.stroke()
                    
                    NSGraphicsContext.restoreGraphicsState()
                })
            } else {
                // Create the stepper touch bar item with built-in value drawing, using a number formatter.
                let formatter = NumberFormatter()
                formatter.numberStyle = .percent
                formatter.maximumFractionDigits = 0
                formatter.multiplier = 1
                
                stepperItem = NSStepperTouchBarItem(identifier: identifier, formatter: formatter)
            }
            
            stepperItem.maxValue = 100
            stepperItem.minValue = 1
            stepperItem.increment = 10
            stepperItem.value = 50
            
            return stepperItem
        default:
            return nil
        }
    }

}
