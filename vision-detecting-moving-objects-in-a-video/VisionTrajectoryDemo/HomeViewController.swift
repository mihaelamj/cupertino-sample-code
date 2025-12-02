/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's home view controller that displays instructions and camera options.
*/

import UIKit
import AVFoundation
import UniformTypeIdentifiers

class HomeViewController: UIViewController {
    
    var recordedVideoURL: URL?
    
    @IBAction func uploadVideoForAnalysis(_ sender: Any) {
        
        // Create a document picker the sample app uses to upload a video to analyze.
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.movie,
                                                                                UTType.video], asCopy: true)
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = false
        present(docPicker, animated: true, completion: nil)
        
    }
    
    @IBAction func startCameraForAnalysis(_ sender: Any) {
        performSegue(withIdentifier: ContentAnalysisViewController.segueDestinationId,
                     sender: self)
    }
    
}

extension HomeViewController: UIDocumentPickerDelegate {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let controller = segue.destination as? ContentAnalysisViewController else {
            print("Failed to load the content analysis view controller.")
            return
        }
        
        guard let videoURL = recordedVideoURL else {
            print("Failed to load a video path.")
            return
        }
        controller.recordedVideoSource = AVAsset(url: videoURL)
    
    }
    
    func  documentPicker(_ controller: UIDocumentPickerViewController,
                         didPickDocumentsAt urls: [URL]) {
        
        guard let url = urls.first else {
            print("Failed to find a document path at the selected path.")
            return
        }
        recordedVideoURL = url
        performSegue(withIdentifier: ContentAnalysisViewController.segueDestinationId,
                     sender: self)
        recordedVideoURL = nil
        
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
}

