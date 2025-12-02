/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ContextMenu object this sample uses to build each context menu.
*/

import UIKit

protocol ContextMenu {
    
    // Adopters of this protocol implement the actual actions.
    func performInspect()
    func performDuplicate()
    func performDelete()
}

extension ContextMenu {
    
    func inspectAction() -> UIAction {
        return UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                        image: UIImage(systemName: "arrow.up.square")) { action in
           self.performInspect()
        }
    }
        
    func duplicateAction() -> UIAction {
        return UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                        image: UIImage(systemName: "plus.square.on.square")) { action in
           self.performDuplicate()
        }
    }
        
    func deleteAction() -> UIAction {
        return UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                        image: UIImage(systemName: "trash"),
                        attributes: .destructive) { action in
           self.performDelete()
        }
    }

}

// MARK: - IndexPathContextMenu

protocol IndexPathContextMenu {
    
    // Adopters of this protocol implement the actual actions.
    func performInspect(_ indexPath: IndexPath)
    func performDuplicate(_ indexPath: IndexPath)
    func performDelete(_ indexPath: IndexPath)
}

extension IndexPathContextMenu {
    
    func inspectAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                        image: UIImage(systemName: "arrow.up.square")) { action in
           self.performInspect(indexPath)
        }
    }
        
    func duplicateAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                        image: UIImage(systemName: "plus.square.on.square")) { action in
           self.performDuplicate(indexPath)
        }
    }
        
    func deleteAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                        image: UIImage(systemName: "trash"),
                        attributes: .destructive) { action in
           self.performDelete(indexPath)
        }
    }

}

// MARK: - WebViewContextMenu

protocol WebViewContextMenu {
    
    // Adopters of this protocol implement the actual actions.
    func performExtra(_ url: URL)
}

extension WebViewContextMenu {
    
    func extraAction(_ url: URL) -> UIAction {
        let imageIcon = UIImage(systemName: "heart.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        return UIAction(title: NSLocalizedString("ExtraTitle", comment: ""),
                        image: imageIcon) { action in
           self.performExtra(url)
        }
    }

}

