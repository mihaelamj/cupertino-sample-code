/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSCustomTouchBarItem with an NSScrubber, using a custom subclass of NSScrubberImageItemView.
*/

import Cocoa

// Button Tag enums. The values have to be the same as the button tags in the storyboard.
private enum KindButtonTag: Int {
    case imageScrubber = 2000, textScrubber = 2001, iconTextScrubber = 2014
}

private enum ModeButtonTag: Int {
    case free = 2002, fixed = 2003
}

private enum SelectionBackgroundStyleButtonTag: Int {
    case none = 2004, boldOutline = 2005, solidBackground = 2006, custom = 2007
}

enum SelectionOverlayStyleButtonTag: Int {
    case none = 2008, boldOutline = 2009, solidBackground = 2010, custom = 2011
}

enum LayoutTypeButtonTag: Int {
    case flow = 2012, proportional = 2013
}

// MARK: -

class ScrubberViewController: NSViewController {
    let scrubberBar = "com.TouchBarCatalog.scrubberBar"
    
    static let imageScrubber = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.imageScrubber")
    static let textScrubber = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.textScrubber")
    static let iconTextScrubber = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.customScrubber")
    
    var selectedItemIdentifier: NSTouchBarItem.Identifier = imageScrubber
    var selectedMode: NSScrubber.Mode = .free
    var selectedSelectionBackgroundStyle: NSScrubberSelectionStyle?
    var selectedSelectionOverlayStyle: NSScrubberSelectionStyle?
    var selectedLayout: NSScrubberLayout = NSScrubberFlowLayout()
    
    @IBOutlet weak var spacingSlider: NSSlider!
    @IBOutlet weak var showsArrows: NSButton!
    @IBOutlet weak var useBackgroundColor: NSButton!
    @IBOutlet weak var useBackgroundView: NSButton!
    @IBOutlet weak var backgroundColorWell: NSColorWell!
    
    // MARK: - Action Functions
    
    @IBAction func customizeAction(_ sender: AnyObject) {
        // This creates a call to makeTouchBar.
		touchBar = nil
    }
    
    @IBAction func useBackgroundColorAction(_ sender: AnyObject) {
        backgroundColorWell.isEnabled = (sender.state == NSControl.StateValue.on)
        // This creates a call to makeTouchBar.
        touchBar = nil
    }
    
    @IBAction func kindAction(_ sender: AnyObject) {
        guard let button = sender as? NSButton, let choice = KindButtonTag(rawValue: button.tag) else { return }
        
        switch choice {
        case .imageScrubber:
            selectedItemIdentifier = ScrubberViewController.imageScrubber
            
        case .textScrubber:
            selectedItemIdentifier = ScrubberViewController.textScrubber
            
        case .iconTextScrubber:
            selectedItemIdentifier = ScrubberViewController.iconTextScrubber
        }
        
        // This creates a call to makeTouchBar..
        touchBar = nil
    }
    
    @IBAction func modeAction(_ sender: AnyObject) {
        guard let button = sender as? NSButton, let choice = ModeButtonTag(rawValue: button.tag) else { return }
        
        switch choice {
        case .free:
            selectedMode = .free
            
        case .fixed:
            selectedMode = .fixed
        }
        
        // This creates a call to makeTouchBar.
        touchBar = nil
    }
    
    @IBAction func selectionAction(_ sender: AnyObject) {
        guard let button = sender as? NSButton, let choice = SelectionBackgroundStyleButtonTag(rawValue: button.tag) else { return }
        
        switch choice {
        case .none:
            selectedSelectionBackgroundStyle = nil
            
        case .boldOutline:
            selectedSelectionBackgroundStyle = .outlineOverlay
            
        case .solidBackground:
            selectedSelectionBackgroundStyle = .roundedBackground
            
        case .custom:
            selectedSelectionBackgroundStyle = CustomSelectionBackgroundStyle()
        }
        
        // This creates a call to makeTouchBar.
        touchBar = nil
    }
    
    @IBAction func overlayAction(_ sender: AnyObject) {
        guard let button = sender as? NSButton, let choice = SelectionOverlayStyleButtonTag(rawValue: button.tag) else { return }
        
        switch choice {
        case .none:
            selectedSelectionOverlayStyle = nil
            
        case .boldOutline:
            selectedSelectionOverlayStyle = .outlineOverlay
            
        case .solidBackground:
            selectedSelectionOverlayStyle = .roundedBackground
            
        case .custom:
            selectedSelectionOverlayStyle = CustomSelectionOverlayStyle()
        }
        
        // This creates a call to makeTouchBar.
        touchBar = nil
    }
    
    @IBAction func flowAction(_ sender: AnyObject) {
		guard let button = sender as? NSButton, let choice = LayoutTypeButtonTag(rawValue: button.tag) else { return }
		
        switch choice {
        case .flow:
			selectedLayout = NSScrubberFlowLayout()
            
        case .proportional:
			selectedLayout = NSScrubberProportionalLayout()
        }
        
        // This creates a call to makeTouchBar.
		touchBar = nil
    }
    
    @IBAction func spacingSliderAction(_ sender: AnyObject) {
        // This creates a call to makeTouchBar.
        touchBar = nil
    }
    
    // MARK: - NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
		touchBar.delegate = self
		
        touchBar.customizationIdentifier = scrubberBar
        touchBar.defaultItemIdentifiers = [selectedItemIdentifier]
        touchBar.customizationAllowedItemIdentifiers = [selectedItemIdentifier]
        touchBar.principalItemIdentifier = selectedItemIdentifier

		return touchBar
    }
}

// MARK: - NSTouchBarDelegate

extension ScrubberViewController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
		let scrubberItem: NSCustomTouchBarItem
        
        switch identifier {
        case ScrubberViewController.textScrubber:
            scrubberItem = TextScrubberBarItemSample(identifier: identifier)
            scrubberItem.customizationLabel = NSLocalizedString("Text Scrubber", comment: "")
            (scrubberItem as? TextScrubberBarItemSample)?.scrubberItemWidth = spacingSlider.integerValue
            
        case ScrubberViewController.imageScrubber:
            scrubberItem = ImageScrubberBarItemSample(identifier: identifier)
            scrubberItem.customizationLabel = NSLocalizedString("Image Scrubber", comment: "")
            (scrubberItem as? ImageScrubberBarItemSample)?.scrubberItemWidth = spacingSlider.integerValue
            
        case ScrubberViewController.iconTextScrubber:
            scrubberItem = IconTextScrubberBarItemSample(identifier: identifier)
            scrubberItem.customizationLabel = NSLocalizedString("IconText Scrubber", comment: "")
            
        default:
            return nil
        }
        
		guard let scrubber = scrubberItem.view as? NSScrubber else { return nil }
        
        scrubber.mode = selectedMode
        scrubber.showsArrowButtons = showsArrows.state == NSControl.StateValue.on
		scrubber.selectionBackgroundStyle = selectedSelectionBackgroundStyle
        scrubber.selectionOverlayStyle = selectedSelectionOverlayStyle
        scrubber.scrubberLayout = selectedLayout
        if useBackgroundColor.state == NSControl.StateValue.on {
            scrubber.backgroundColor = backgroundColorWell.color
        }
        
        if useBackgroundView.state == NSControl.StateValue.on {
            scrubber.backgroundView = CustomBackgroundView()
        }
        
        // Set the scrubber's width to be 400.
        let viewBindings: [String: NSView] = ["scrubber": scrubber]
        let hconstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:[scrubber(400)]",
                                                          options: [],
                                                          metrics: nil,
                                                          views: viewBindings)
        NSLayoutConstraint.activate(hconstraints)
        
        return scrubberItem
    }
}

