/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's error-handling type.
*/

import UIKit

enum AppError: Error {
    
    case captureSessionSetup(reason: String)
    case createRequestError(reason: String)
    case videoReadingError(reason: String)
    
    static func display(_ error: Error,
                        inViewController viewController: UIViewController) {
        
        guard let err = error as? AppError else {
            print("Failed to get an app error type.")
            return
        }
        err.displayInViewController(viewController)
        
    }
    
    func displayInViewController(_ viewController: UIViewController) {
        
        let title: String?
        let message: String?
        
        switch self {
        case .captureSessionSetup(let reason):
            title = "AVSession Setup Error"
            message = reason
        case .createRequestError(let reason):
            title = "Error Creating Vision Request"
            message = reason
        case .videoReadingError(let reason):
            title = "Error Reading Recorded Video"
            message = reason
        }
        
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
        
    }
    
}
