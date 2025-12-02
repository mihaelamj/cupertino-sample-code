/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates attaching a menu to a bar button item.
*/

import UIKit

class BarButtonMenu: UIViewController {
    
    @IBOutlet var optionsBarItem: UIBarButtonItem!
    
    func menuHandler(action: UIAction) {
        Swift.debugPrint("Menu handler: \(action.title)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let barButtonMenu = UIMenu(title: "", children: [
            UIAction(title: NSLocalizedString("Copy", comment: ""), image: UIImage(systemName: "doc.on.doc"), handler: menuHandler),
            UIAction(title: NSLocalizedString("Rename", comment: ""), image: UIImage(systemName: "pencil"), handler: menuHandler),
            UIAction(title: NSLocalizedString("Duplicate", comment: ""), image: UIImage(systemName: "plus.square.on.square"), handler: menuHandler),
            UIAction(title: NSLocalizedString("Move", comment: ""), image: UIImage(systemName: "folder"), handler: menuHandler)
        ])
        optionsBarItem.menu = barButtonMenu
    }
}
