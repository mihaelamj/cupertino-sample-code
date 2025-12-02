/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A set of action handlers that support buttons in the main view controller.
*/

import UIKit
import CoreData

extension MainViewController {
    // Create the new post on the main queue context, so there’s no need to dispatch a UI update to the main queue.
    @IBAction func add(_ sender: UIBarButtonItem) {
        dataProvider.addPost(in: dataProvider.persistentContainer.viewContext) { post in
            self.didUpdatePost(post)
        }
    }
        
    @IBAction func compose(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) {_ in
            self.dismiss(animated: true)
        })
        
        alertController.addAction(UIAlertAction(title: "Manage Tags", style: .default) {_ in
            self.dismiss(animated: true)
            self.performSegue(withIdentifier: "Tags", sender: self)
        })
        
        alertController.addAction(self.generate1000PostsAlertAction())
        alertController.addAction(self.largeDataAlertAction())
        
        if tableView.numberOfRows(inSection: 0) > 0 {
            alertController.addAction(UIAlertAction(title: "Delete All Posts", style: .destructive) {_ in
                self.showSpinner()
                
                // Batch delete all posts, and refresh the UI afterward.
                self.dataProvider.batchDeleteAllPosts() {
                    self.dismissSpinner(reloadPost: nil)
                }
                self.dismiss(animated: true)
            })
        }
        
        present(alertController, animated: true)
    }
    
    func showSpinner() {
        self.spinner.startAnimating()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
    }
    
    func dismissSpinner(reloadPost: Post?) {
        DispatchQueue.main.async {
            self.resetAndReload(select: reloadPost)
            self.spinner.stopAnimating()
        }
    }
    
    func generate1000PostsAlertAction() -> UIAlertAction {
        return UIAlertAction(title: "Generate 1000 Posts", style: .default) {_ in
            self.showSpinner()
            var selectedPost: Post? = nil
            if let indexPath = self.tableView.indexPathForSelectedRow {
                selectedPost = self.dataProvider.fetchedResultsController.object(at: indexPath)
            }
            
            self.dataProvider.generateTemplatePosts(number: 1000) {
                self.dismissSpinner(reloadPost: selectedPost)
            }
            self.dismiss(animated: true)
        }
    }
    
    func largeDataAlertAction() -> UIAlertAction {
        return UIAlertAction(title: "Generator: Large Data", style: .default) {_ in
            self.showSpinner()
            let generator = LargeDataGenerator()
            let context = self.dataProvider.persistentContainer.newBackgroundContext()
            do {
                try generator.generateData(context: context)
                self.dismissSpinner(reloadPost: nil)
            } catch {
                print("Failed to generate data: \(error)")
            }
            self.dismiss(animated: true)
        }
    }
}
