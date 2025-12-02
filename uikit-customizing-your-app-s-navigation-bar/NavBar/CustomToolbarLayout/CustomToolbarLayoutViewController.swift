/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates a custom toolbar layout.
*/

import UIKit

class CustomToolbarLayoutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Builds the navigation bar.
        let selectBarButton = UIBarButtonItem(title: NSLocalizedString("Select", comment: ""),
                                              style: .plain,
                                              target: nil,
                                              action: nil)
        let shareBarButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                             style: .plain,
                                             target: nil,
                                             action: nil)
        let infoBarButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                                            style: .plain,
                                            target: nil,
                                            action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                            target: nil,
                                            action: nil)

        navigationItem.rightBarButtonItems = [doneBarButton,
                                              shareBarButton,
                                              infoBarButton,
                                              selectBarButton]

        // Builds the toolbar.
        let flexibleSpace = UIBarButtonItem.flexibleSpace()
        
        flexibleSpace.hidesSharedBackground = false
        
        toolbarItems = [
            .init(image: UIImage(systemName: "location")),
            flexibleSpace,
            .init(image: UIImage(systemName: "number")),
            flexibleSpace,
            .init(image: UIImage(systemName: "camera")),
            flexibleSpace,
            .init(image: UIImage(systemName: "trash"))
        ]
    }
}
