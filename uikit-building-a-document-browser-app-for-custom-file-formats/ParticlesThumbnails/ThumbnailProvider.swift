/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A thumbnail provider that generates a graphical representation of a document at a URL.
*/

import UIKit
import QuickLook

class ThumbnailProvider: QLThumbnailProvider {
    
    // Main method to implement in order to provide thumbnails for files.
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        let fileURL = request.fileURL
        let maximumSize = request.maximumSize
        let scale = request.scale
        
        // Make use of the parameters of the request to determine the context size for the subsequent steps.
        let contextSize = contextSizeForFile(at: fileURL, maximumSize: maximumSize, scale: scale)
        
        let frame = CGRect(origin: .zero, size: contextSize)
        
        let document = Document(fileURL: fileURL)
        document.open { (success) in
            guard success else {
                handler(nil, document.error)
                return
            }

            // This example is based on having a thumbnail for our document that comes from
            // a snapshot of the view we would use to display the document if opened in the app.
            // As such, we have to dispatch to the main queue to get a snapshot of it, since it's
            // a call on an UIKit view.
            //
            // If you can render your thumbnail in a thread-safe way instead, without leveraging
            // your app's UI layer, it will lead to better performance as Quick Look will be able
            // to compute multiple thumbnails in parallel.
            
            DispatchQueue.main.async {
                let particleViewController = ParticleViewController()
                particleViewController.view.frame = frame
                particleViewController.view.layoutIfNeeded()
                particleViewController.document = document
                
                var snapshot = particleViewController.snapshot()
                
                // Make sure the snapshot will be drawn at the expected scale in the current context below
                
                if snapshot.scale != scale, let cgImage = snapshot.cgImage {
                    snapshot = UIImage(cgImage: cgImage, scale: scale, orientation: .up)
                }
                
                let reply = QLThumbnailReply(contextSize: contextSize, currentContextDrawing: {
                    snapshot.draw(at: .zero)
                    return true
                })
                
                document.close { success in
                    // The document is read-only here so saving should be a no-op and never fail.
                    assert(success, "The document was not modified so closing it should not fail")
                }
                handler(reply, nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func contextSizeForFile(at URL: URL, maximumSize: CGSize, scale: CGFloat) -> CGSize {
        
        // In the case of the Particles files, the maximum requested size can be honored.
        return maximumSize
    }
    
}
