/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ViewController drives a PDFView, loading a PDF document, and inserts a few interactive annotations (widgets).
*/

import UIKit
import PDFKit

/**
 ViewController first loads a path to our MyForm.pdf file through the application's main bundle. This URL
 is then used to instantiate a PDFDocument. On success, the document is assigned to our PDFView, which
 was setup in InterfaceBuilder. Once the document has been successfully loaded, we can extract the first
 page in order to begin adding our widget annotations.
 
 ViewController adds the following widget types to the extracted PDFPage: three text fields, two radio
 buttons, three checkboxes, and one push button. To tell PDFKit which type of interactive element to add
 to your document, you must explicitly set the widgetFieldType. Similarly, for button widgets you must
 explicitly set the widgetControlType.
 
 This class also includes a few extra widget-specific properties which are worth mentioning:
 maximumLength & hasComb, fieldName & buttonWidgetStateString, isMultiline, and action & PDFActionResetForm.
 
 See the README for more detail on both widget annotation creation, and in-depth explanations regarding the
 widget-specific properties.
*/
class ViewController: UIViewController {

    @IBOutlet weak var pdfView: PDFView?

    func insertFormFieldsInto(_ page: PDFPage) {

        let pageBounds = page.bounds(for: .cropBox)

        // Intro: "Name:" & "Date:"
        let textFieldNameBounds = CGRect(x: 169, y: pageBounds.size.height - 102, width: 371, height: 23)
        let textFieldName = PDFAnnotation(bounds: textFieldNameBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        textFieldName.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.text.rawValue)
        textFieldName.backgroundColor = UIColor.blue.withAlphaComponent(0.25)
        textFieldName.font = UIFont.systemFont(ofSize: 18)
        page.addAnnotation(textFieldName)

        let textFieldDateBounds = CGRect(x: 283, y: pageBounds.size.height - 135, width: 257, height: 22)
        let textFieldDate = PDFAnnotation(bounds: textFieldDateBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        textFieldDate.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.text.rawValue)
        textFieldDate.backgroundColor = UIColor.blue.withAlphaComponent(0.25)
        textFieldDate.font = UIFont.systemFont(ofSize: 18)
        textFieldDate.maximumLength = 5
        textFieldDate.hasComb = true
        page.addAnnotation(textFieldDate)
    }

    func insertRadioButtonsInto(_ page: PDFPage) {

        let pageBounds = page.bounds(for: .cropBox)

        // Yes button
        let radioButtonYesBounds = CGRect(x: 135, y: pageBounds.size.height - 249, width: 24, height: 24)
        let radioButtonYes = PDFAnnotation(bounds: radioButtonYesBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        radioButtonYes.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.button.rawValue)
        radioButtonYes.widgetControlType = .radioButtonControl
        radioButtonYes.fieldName = "Radio Button"
        radioButtonYes.buttonWidgetStateString = "Yes"
        page.addAnnotation(radioButtonYes)

        // No button
        let radioButtonNoBounds = CGRect(x: 210, y: pageBounds.size.height - 249, width: 24, height: 24)
        let radioButtonNo = PDFAnnotation(bounds: radioButtonNoBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        radioButtonNo.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.button.rawValue)
        radioButtonNo.widgetControlType = .radioButtonControl
        radioButtonNo.fieldName = "Radio Button"
        radioButtonNo.buttonWidgetStateString = "No"
        page.addAnnotation(radioButtonNo)
    }

    func insertCheckBoxesInto(_ page: PDFPage) {

        let pageBounds = page.bounds(for: .cropBox)

        let checkboxLoremFestivalBounds = CGRect(x: 255, y: pageBounds.size.height - 370, width: 24, height: 24)
        let checkboxLoremFestival = PDFAnnotation(bounds: checkboxLoremFestivalBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        checkboxLoremFestival.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.button.rawValue)
        checkboxLoremFestival.widgetControlType = .checkBoxControl
        page.addAnnotation(checkboxLoremFestival)

        let checkboxIpsumFestivalBounds = CGRect(x: 255, y: pageBounds.size.height - 417, width: 24, height: 24)
        let checkboxIpsumFestival = PDFAnnotation(bounds: checkboxIpsumFestivalBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        checkboxIpsumFestival.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.button.rawValue)
        checkboxIpsumFestival.widgetControlType = .checkBoxControl
        page.addAnnotation(checkboxIpsumFestival)

        let checkboxDolorFestivalBounds = CGRect(x: 255, y: pageBounds.size.height - 464, width: 24, height: 24)
        let checkboxDolorFestival = PDFAnnotation(bounds: checkboxDolorFestivalBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        checkboxDolorFestival.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.button.rawValue)
        checkboxDolorFestival.widgetControlType = .checkBoxControl
        page.addAnnotation(checkboxDolorFestival)
    }

    func insertMultilineTextBoxInto(_ page: PDFPage) {

        let pageBounds = page.bounds(for: .cropBox)

        let textFieldMultilineBounds = CGRect(x: 90, y: pageBounds.size.height - 632, width: 276, height: 80)
        let textFieldMultiline = PDFAnnotation(bounds: textFieldMultilineBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        textFieldMultiline.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.text.rawValue)
        textFieldMultiline.backgroundColor = UIColor.blue.withAlphaComponent(0.25)
        textFieldMultiline.font = UIFont.systemFont(ofSize: 24)
        textFieldMultiline.isMultiline = true
        page.addAnnotation(textFieldMultiline)
    }

    func insertResetButtonInto(_ page: PDFPage) {

        let pageBounds = page.bounds(for: .cropBox)

        let resetButtonBounds = CGRect(x: 90, y: pageBounds.size.height - 680, width: 106, height: 32)
        let resetButton = PDFAnnotation(bounds: resetButtonBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
        resetButton.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.button.rawValue)
        resetButton.widgetControlType = .pushButtonControl
        resetButton.caption = "Reset"
        page.addAnnotation(resetButton)

        // Create PDFActionResetForm action to clear form fields.
        let resetFormAction = PDFActionResetForm()
        resetFormAction.fieldsIncludedAreCleared = false
        resetButton.action = resetFormAction
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        // Load our simple PDF document, retrieve the first page
        if let documentURL = Bundle.main.url(forResource: "MyForm", withExtension: "pdf"),
            let document = PDFDocument(url: documentURL),
            let page = document.page(at: 0) {

            // Set our document to the view, center it, and set a background color
            pdfView?.document = document
            pdfView?.autoScales = true
            pdfView?.backgroundColor = UIColor.lightGray

            // Add Name: and Date: fields
            self.insertFormFieldsInto(page)

            // Add Question 1 widgets: "Have you been to a music festival before?"
            self.insertRadioButtonsInto(page)

            // Add Question 2 widgets: "Which of the following music festivals have you attended?"
            self.insertCheckBoxesInto(page)

            // Question 3: "Give one recommendation to improve a music festival:"
            self.insertMultilineTextBoxInto(page)

            // Reset Form
            self.insertResetButtonInto(page)
        }
    }
}
