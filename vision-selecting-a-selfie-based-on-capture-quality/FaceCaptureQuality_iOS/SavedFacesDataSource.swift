/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data source implementing the storage abstraction to keep face-capture quality scores.
*/

import UIKit
import Vision

class SavedFacesDataSource {
    
    struct SavedFace {
        var url: URL
        var qualityScore: Float
    }
    
    let baseURL: URL
    var savedFaces = [SavedFace]()
    
    init() {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to locate Documents directory.")
        }
        self.baseURL = docsURL
        removePreviouslySavedFaces()
    }
    
    func saveFaceCrop(_ jpegData: Data, faceId: String, qualityScore: Float) {
        let fileURL = baseURL.appendingPathComponent(faceId).appendingPathExtension("jpeg")
        do {
            try jpegData.write(to: fileURL)
            let newFace = SavedFace(url: fileURL, qualityScore: qualityScore)
            savedFaces.append(newFace)
        } catch {
            print("Unable to save face crop: \(error.localizedDescription)")
        }
    }
    
    func removePreviouslySavedFaces() {
        let fileMgr = FileManager.default
        guard let files = try? fileMgr.contentsOfDirectory(at: baseURL, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? fileMgr.removeItem(at: file)
        }
        savedFaces.removeAll()
    }
}
