/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Description about what the file includes goes here.
*/

import UIKit
import VisionKit
import Vision

class DataGatheringViewController: UIViewController {

    static let businessCardContentsID = "businessCardContentsVC"
    static let receiptContentsID = "receiptContentsVC"
    static let otherContentsID = "otherContentsVC"

    enum ScanMode: Int {
        case receipts
        case businessCards
        case other
    }
    
    var scanMode: ScanMode = .receipts
    var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    var textRecognitionRequest = VNRecognizeTextRequest()

    override func viewDidLoad() {
        super.viewDidLoad()
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in
            guard let resultsViewController = self.resultsViewController else {
                print("resultsViewController is not set")
                return
            }
            if let results = request.results, !results.isEmpty {
                if let results = request.results as? [VNRecognizedTextObservation] {
                    resultsViewController.addRecognizedText(recognizedText: results)
                }
            }
        })
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
    }

    @IBAction func scan(_ sender: UIControl) {
        scanMode = ScanMode(rawValue: sender.tag)!
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
    func processImage(image: UIImage) {
        guard let cgImage = image.cgImage else {
            print("Failed to get cgimage from input image")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
    }
}

extension DataGatheringViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        switch scanMode {
        case .receipts:
            resultsViewController = storyboard?.instantiateViewController(withIdentifier: DataGatheringViewController.receiptContentsID)
        case .businessCards:
            resultsViewController = storyboard?.instantiateViewController(withIdentifier: DataGatheringViewController.businessCardContentsID)
        default:
            resultsViewController = storyboard?.instantiateViewController(withIdentifier: DataGatheringViewController.otherContentsID)
        }
        
        controller.dismiss(animated: true) {
            if let resultsVC = self.resultsViewController {
                self.navigationController?.pushViewController(resultsVC, animated: true)
            }
        }
        for pageNumber in 0 ..< scan.pageCount {
            let image = scan.imageOfPage(at: pageNumber)
            processImage(image: image)
        }
    }
}
