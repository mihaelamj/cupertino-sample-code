/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ViewController is the main view controller of DocumentWatermark. It drives the
 main PDFView display and loading of a PDFDocument.
*/

import UIKit
import PDFKit

/**
 This ViewController initializes a PDFDocument, sets its delegate to self, and implements
 the classForPage() delegate method. This declares that all instantiated PDFPages for
 the presented document (through PDFView) should instantiate the subclass WatermarkPage instead.
 This subclass, found in WatermarkPage.swift, implements custom drawing.
 
 ViewController first loads a path to our Sample.pdf file through the application's
 main bundle. This URL is then used to instantiate a PDFDocument. On success, the document
 is assigned to our PDFView, which was setup in InterfaceBuilder.
 
 Before document assignment, it is critical to assign our delegate, which is the ViewController
 itself, so that classForPage() (a PDFDocumentDelgetate method) implements classForPage().
 This method returns the PDFPage subclass used for custom drawing.
*/
class ViewController: UIViewController, PDFDocumentDelegate {

    @IBOutlet weak var pdfView: PDFView?

    /// - Tag: SetDelegate
    override func viewDidLoad() {
        super.viewDidLoad()

        if let documentURL = Bundle.main.url(forResource: "Sample", withExtension: "pdf") {
            if let document = PDFDocument(url: documentURL) {

                // Center document on gray background
                pdfView?.autoScales = true
                pdfView?.backgroundColor = UIColor.lightGray

                // 1. Set delegate
                document.delegate = self
                pdfView?.document = document
            }
        }
    }

    // 2. Return your custom PDFPage class
    /// - Tag: ClassForPage
    func classForPage() -> AnyClass {
        return WatermarkPage.self
    }

}
