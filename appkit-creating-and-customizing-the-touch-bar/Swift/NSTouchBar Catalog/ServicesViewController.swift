/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSSharingServicePickerTouchBarItem in an NSTouchBar instance.
*/

import Cocoa

class ServicesViewController: NSViewController {
    let servicesBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.servicesBar")
    let services = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.services")
    
    var imageToSend = NSImage(named: "image3")!
    
    // MARK: - NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        
        touchBar.customizationIdentifier = servicesBar
        touchBar.defaultItemIdentifiers = [services]
        touchBar.customizationAllowedItemIdentifiers = [services]
        touchBar.principalItemIdentifier = services
        
        return touchBar
    }
}

// MARK: - NSTouchBarDelegate

extension ServicesViewController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard identifier == services else { return nil }
        
        let services = NSSharingServicePickerTouchBarItem(identifier: identifier)
        services.delegate = self
        
        return services
    }
}

// MARK: - NSSharingServicePickerTouchBarItemDelegate

extension ServicesViewController: NSSharingServicePickerTouchBarItemDelegate {
    func items(for pickerTouchBarItem: NSSharingServicePickerTouchBarItem) -> [Any] {
        return [imageToSend]
    }
    
}

// MARK: - NSSharingServiceDelegate

extension ServicesViewController: NSSharingServiceDelegate {
    
    // MARK: - NSSharingServicePickerDelegate
    
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker,
                              delegateFor sharingService: NSSharingService) -> NSSharingServiceDelegate? {
        return self
    }
    
    // MARK: - NSSharingServiceDelegate
    
    func sharingService(_ sharingService: NSSharingService, sourceFrameOnScreenForShareItem item: Any) -> NSRect {
        return NSRect(x: 0, y: 0, width: imageToSend.size.width, height: imageToSend.size.height)
    }
    
    func sharingService(_ sharingService: NSSharingService,
                        transitionImageForShareItem item: Any, contentRect: UnsafeMutablePointer<NSRect>) -> NSImage? {
        return imageToSend
    }
    
    public func sharingService(_ sharingService: NSSharingService,
                               sourceWindowForShareItems items: [Any],
                               sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>) -> NSWindow? {
        return view.window
    }
    
}

