/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The secondary inspector view controller that displays an individual photo.
*/

import UIKit

class InspectorViewController: UIViewController {
    @IBOutlet var photoImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction(_:)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        // Set up this view controller based on its 'userActivity'.
        if let userInfo = userActivity?.userInfo {
            if let imageName = userInfo[UserActivity.GalleryOpenDetailPhotoAssetKey] as? String {
                photoImageView.image = UIImage(named: imageName)
            }
            if let photoTitle = userInfo[UserActivity.GalleryOpenDetailPhotoTitleKey] as? String {
                title = photoTitle
            }
        }
        
        #if targetEnvironment(macCatalyst) // No navigation bar in macOS.
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.window?.windowScene?.userActivity = userActivity
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.window?.windowScene?.userActivity = nil
    }
    
    @IBAction func closeAction(_ sender: Any) {
        guard let scene = view.window?.windowScene else { return }
        
        // The Done button is shown only for iPadOS, and when tapped, it removes the scene.
        let options = UIWindowSceneDestructionRequestOptions()
        
        // Pick a dismissal animation when the window scene goes away.
        options.windowDismissalAnimation = .standard
        // Other animation options are:
        //      '.commit' will move the window upward off the device.
        //      '.decline' will move the window downward off the device.
        
        UIApplication.shared.requestSceneSessionDestruction(scene.session, options: options, errorHandler: { error in
            // Handle the error.
        })
    }
    
}
