/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A UIViewController subclass for adding a new feedback object.
*/

import UIKit

class FeedbackViewController: UITableViewController {

    @IBOutlet weak var ratingSegmentedControl: UISegmentedControl!
    @IBOutlet weak var commentTextView: UITextView!
    
    var book: Book!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = book.title
        commentTextView.text = nil
    }
}

// MARK: - Actions
//
extension FeedbackViewController {

    @IBAction func done(_ sender: Any) {
        guard let context = book.managedObjectContext else { return }
        
        let newFeedback = Feedback(context: context)
        newFeedback.comment = commentTextView.text
        newFeedback.bookUUID = book.uuid
        newFeedback.rating = Int16(ratingSegmentedControl.selectedSegmentIndex)
        do {
            try context.save()
        } catch {
            print("Failed to save feedback: \(error)")
        }
        context.refresh(book, mergeChanges: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
