/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Special NSTouchBar subclass for the PopoverViewController.
*/

import Cocoa

class PopoverTouchBarSample: NSTouchBar {
    
    let button = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.button")
    let dismissButton = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.dismissButton")
    let slider = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.slider")
    
    var presentingItem: NSPopoverTouchBarItem?
    
    @objc
    func dismiss(_ sender: Any?) {
        guard let popover = presentingItem else { return }
        popover.dismissPopover(sender)
    }
    
    override init() {
        super.init()
        
        delegate = self
        defaultItemIdentifiers = [button, slider]
    }
    
    required init?(coder aDecoder: NSCoder) {
        // This system always creates this particular touch bar programmatically.
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(presentingItem: NSPopoverTouchBarItem? = nil, forPressAndHold: Bool = false) {
        self.init()
        self.presentingItem = presentingItem
        
        /** Sliders only work well with press and hold behavior when they are the only item in the popover
            and you use the slider popover item.
        */
        if forPressAndHold {
            defaultItemIdentifiers = [slider]
            return
        }
        
        if let showsCloseButton = presentingItem?.showsCloseButton, showsCloseButton == false {
            defaultItemIdentifiers = [dismissButton, button, slider]
        }
    }
    
    @objc
    func actionHandler(_ sender: Any?) {
        print("\(#function) is called")
    }
    
    @objc
    func sliderValueChanged(_ sender: Any) {
        if let sliderItem = sender as? NSSliderTouchBarItem {
            print("Slider value: \(sliderItem.slider.intValue)")
        }
    }
}

// MARK: - NSTouchBarDelegate

extension PopoverTouchBarSample: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case button:
            let custom = NSCustomTouchBarItem(identifier: identifier)
            custom.customizationLabel = NSLocalizedString("Button", comment: "")
            custom.view = NSButton(title: NSLocalizedString("Button", comment: ""), target: self, action: #selector(actionHandler(_:)))
            return custom
            
        case dismissButton:
            let custom = NSCustomTouchBarItem(identifier: identifier)
            custom.customizationLabel = NSLocalizedString("Button Button", comment: "")
            custom.view = NSButton(title: NSLocalizedString("Close", comment: ""),
                                   target: self,
                                   action: #selector(PopoverTouchBarSample.dismiss(_:)))
            return custom
            
        case slider:
            let sliderItem = NSSliderTouchBarItem(identifier: identifier)
            let slider = sliderItem.slider
            slider.minValue = 0.0
            slider.maxValue = 100.0
            sliderItem.label = NSLocalizedString("Slider", comment: "")
            
            sliderItem.customizationLabel = NSLocalizedString("Slider", comment: "")
            sliderItem.target = self
            sliderItem.action = #selector(sliderValueChanged(_:))
            
            let viewBindings: [String: NSView] = ["slider": slider]
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: "[slider(300)]",
                                                             options: [],
                                                             metrics: nil,
                                                             views: viewBindings)
            NSLayoutConstraint.activate(constraints)
            return sliderItem
            
        default:
            return nil
        }
    }
}

