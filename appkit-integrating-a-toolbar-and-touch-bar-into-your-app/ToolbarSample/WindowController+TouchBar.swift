/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Touch Bar support for the window controller.
*/

import Cocoa

private extension NSTouchBar.CustomizationIdentifier {
    static let touchBar = "com.ToolbarSample.touchBar"
}

extension NSTouchBarItem.Identifier {
    static let popover = NSTouchBarItem.Identifier("com.ToolbarSample.TouchBarItem.popover")
    static let fontStyle = NSTouchBarItem.Identifier("com.ToolbarSample.TouchBarItem.fontStyle")
    static let popoverSlider = NSTouchBarItem.Identifier("com.ToolbarSample.popoverBar.slider")
}

extension WindowController: NSTouchBarDelegate {
    
/// - Tag: CreateTouchBar
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .touchBar
        touchBar.defaultItemIdentifiers = [.fontStyle, .popover, NSTouchBarItem.Identifier.otherItemsProxy]
        touchBar.customizationAllowedItemIdentifiers = [.fontStyle, .popover]
        
        return touchBar
    }

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.popover:
            
            let popoverItem = NSPopoverTouchBarItem(identifier: identifier)
            popoverItem.customizationLabel = NSLocalizedString("Font Size", comment: "")
            popoverItem.collapsedRepresentationLabel = NSLocalizedString("Font Size", comment: "")
            
            let secondaryTouchBar = NSTouchBar()
            secondaryTouchBar.delegate = self
            secondaryTouchBar.defaultItemIdentifiers = [.popoverSlider]
            
            /** We can setup a different NSTouchBar instance for popoverTouchBar and pressAndHoldTouchBar
             	property. Here we just use the same instance.
             */
            popoverItem.pressAndHoldTouchBar = secondaryTouchBar
            popoverItem.popoverTouchBar = secondaryTouchBar
            
            return popoverItem
            
        case NSTouchBarItem.Identifier.fontStyle:
            let fontStyleItem = NSCustomTouchBarItem(identifier: identifier)
            fontStyleItem.customizationLabel = NSLocalizedString("Font Style", comment: "")
            
            let fontStyleSegment =
                NSSegmentedControl(labels: [NSLocalizedString("Plain", comment: ""),
                                            NSLocalizedString("Bold", comment: ""),
                                            NSLocalizedString("Italic", comment: "")],
                                   trackingMode: .momentary,
                                   target: self,
                                   action: #selector(changeFontStyleBySegment))
            
            fontStyleItem.view = fontStyleSegment
            
            return fontStyleItem
            
        case NSTouchBarItem.Identifier.popoverSlider:
            let sliderItem = NSSliderTouchBarItem(identifier: identifier)
            sliderItem.label = NSLocalizedString("Size", comment: "")
            sliderItem.customizationLabel = NSLocalizedString("Font Size", comment: "")
            
            let slider = sliderItem.slider
            slider.minValue = 6.0
            slider.maxValue = 100.0
            slider.target = self
            slider.action = #selector(changeFontSizeBySlider)
            
            // Set the font size for the slider item to the same value as the stepper.
            slider.integerValue = defaultFontSize
            
            slider.bind(NSBindingName.value, to: self, withKeyPath: "currentFontSize", options: nil)
            
            return sliderItem
            
        default: return nil
        }
    }
    
    // Called when the user chooses a font style from the segmented control inside the NSTouchBar instance.
    @IBAction func touchBarFontStyleAction(_ sender: NSSegmentedControl) {
        setTextViewFont(index: sender.selectedSegment)
    }
    
}
