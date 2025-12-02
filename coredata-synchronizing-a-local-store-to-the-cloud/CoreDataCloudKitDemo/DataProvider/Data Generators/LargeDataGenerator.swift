/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to generate a large data set.
*/

import Foundation
import CoreData
import UIKit

class LargeDataGenerator {
    func generateData(context: NSManagedObjectContext) throws {
        var postContent = ""
        for iteration in 1...50 {
            postContent.append("This is a sample string (iteration \(iteration)) that has been concatenated together to give a longer post content.")
            postContent.append("This repetitive text probably compresses better than human-generated text.")
            postContent.append("However, it produces representative memory and time complexity data for working with content of this size.")
        }
        
        try context.performAndWait {
            for postCount in 1...60 {
                let post = Post(context: context)
                post.title = "Post \(postCount)"
                post.content = postContent
                
                for attachmentCount in 1...11 {
                    let attachment = Attachment(context: context)
                    attachment.uuid = UUID()
                    attachment.post = post
                    
                    let imageData = ImageData(context: context)
                    imageData.attachment = attachment
                    
                    imageData.data = autoreleasepool {
                        let url = Bundle(for: type(of: self)).url(forResource: "image\(attachmentCount)", withExtension: "png")
                        let imageFileData = NSData(contentsOf: url!)!
                        return imageFileData as Data
                    }
                }
  
                let saveCount = 5
                if 0 == (postCount % saveCount) {
                    try context.save()
                    context.reset()
                }
            }
            
            if context.hasChanges {
                try context.save()
                context.reset()
            }
        }
    }
}
