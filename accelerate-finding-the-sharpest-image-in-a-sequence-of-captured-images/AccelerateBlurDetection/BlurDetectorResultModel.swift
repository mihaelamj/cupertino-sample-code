/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that represents blur detection results.
*/

import AVFoundation
import Accelerate
import UIKit
import SwiftUI
import Combine

// MARK: BlurDetectorResultModel

class BlurDetectorResultModel: ObservableObject, BlurDetectorResultsDelegate {
    
    enum Mode {
         case camera
         case processing
         case resultsTable
     }

    @Published var blurDetectionResults = [BlurDetectionResult]()
    
    @Published var mode: Mode = .camera {
        didSet {
            if mode == .processing {
                blurDetectionResults.removeAll()
            }
            showResultsTable = mode == .resultsTable
        }
    }

    @Published var showResultsTable = false
    
    func itemProcessed(_ item: BlurDetectionResult) {
        blurDetectionResults.append(item)
    }
    
    func finishedProcessing() {
        // Sort results: variance of Laplacian - higher is less blurry.
        blurDetectionResults.sort {
            $0.score > $1.score
        }
        
        mode = .resultsTable
    }
}
