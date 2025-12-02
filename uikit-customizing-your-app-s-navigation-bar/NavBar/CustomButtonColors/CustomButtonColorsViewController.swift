/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates custom button colors in a navigation bar.
*/

import UIKit

class CustomButtonColorsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let selectBarButton = UIBarButtonItem(title: NSLocalizedString("Select", comment: ""),
                                              style: .plain,
                                              target: nil,
                                              action: nil)

        let shareBarButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                             style: .plain,
                                             target: nil,
                                             action: nil)
        shareBarButton.tintColor = .systemOrange
        
        let infoBarButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                                            style: .plain,
                                            target: nil,
                                            action: nil)
        infoBarButton.tintColor = .systemOrange
        infoBarButton.style = .prominent
        
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                            target: nil,
                                            action: nil)

        navigationItem.rightBarButtonItems = [doneBarButton,
                                              shareBarButton,
                                              .fixedSpace(0),
                                              infoBarButton,
                                              selectBarButton]
    }
}
