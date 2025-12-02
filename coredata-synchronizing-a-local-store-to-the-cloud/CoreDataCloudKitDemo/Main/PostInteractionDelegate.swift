/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interaction protocol between the main view controller and detail view controller.
*/

protocol PostInteractionDelegate: AnyObject {
    /**
     When the detail view controller has finished an edit, it calls didUpdatePost for the delegate (the main view controller)
     to update the user interface.
     
     When deleting a post, pass nil for post.
     */
    func didUpdatePost(_ post: Post?, shouldReloadRow: Bool)
    
    /**
     UISplitViewController can show the detail view controller when it is appropriate.
     
     In that case, the main and detail view controllers may not be connected yet.
     
     In the detail view controller’s willAppear, call this method so that the main view controller can build the connection.
     */
    func willShowDetailViewController(_ controller: DetailViewController)
}
