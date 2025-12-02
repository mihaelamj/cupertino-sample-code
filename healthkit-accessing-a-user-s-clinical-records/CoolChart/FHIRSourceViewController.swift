/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for displaying the raw FHIR JSON.
*/

import HealthKit
import UIKit

class FHIRSourceViewController: UIViewController {
    let fhirResource: HKFHIRResource
    
    var sourceView: UITextView!
    
    /// Initialize the view with the FHIR resource JSON.
    init(fhirResource: HKFHIRResource) {
        self.fhirResource = fhirResource
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    // MARK: - View Lifecyle
    
    /// Set up the display options for this text view.
    override func viewDidLoad() {
        super.viewDidLoad()
        title = coolify("FHIR Source")
        
        view.backgroundColor = UIColor.white
        
        sourceView = UITextView(frame: .null)
        sourceView.isEditable = false
        sourceView.textColor = UIColor.darkGray
        sourceView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sourceView)
        
        sourceView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        sourceView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        sourceView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        sourceView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        do {
            try displaySourceData(fhirResource.data)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: -
    
    /// Display any relevant errors in an alert controller.
    func handleError(_ error: Error?) {
        let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alertController, animated: true)
    }
    
    /// Reencode the FHIR source data as pretty-printed JSON
    func displaySourceData(_ sourceData: Data) throws {
        let sourceObject = try JSONSerialization.jsonObject(with: sourceData, options: [])
        let prettyPrintedSourceData = try JSONSerialization.data(withJSONObject: sourceObject, options: [.prettyPrinted])
        
        let sourceString = String(data: prettyPrintedSourceData, encoding: .utf8) ?? "Unable to display FHIR source."
        
        sourceView.text = unescapeJSONString(sourceString)
    }
}
