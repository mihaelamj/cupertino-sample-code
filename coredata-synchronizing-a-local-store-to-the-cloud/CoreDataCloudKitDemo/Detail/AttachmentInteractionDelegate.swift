/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol describing the interaction between an attachment collection cell, attachment cell, and the detail view controller.
*/

import UIKit

protocol AttachmentInteractionDelegate: AnyObject {
    /**
     Presents the full image.
     
     When the user taps a cell, the cell calls this method to notify the delegate (the detail view controller) to present the  associated image.
     */
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    
    /**
     Deletes the attachment.
     
     When the user deletes a cell, the cell calls this method to notify the delegate (the detail view controller) to delete the attachment.
     */
    func delete(attachment: Attachment, at indexPath: IndexPath)
}
