/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Vision view controller, which recognizes and displays bounding boxes around text.
*/

import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: ViewController {
    
	var request: VNRecognizeTextRequest!
	// The temporal string tracker.
	let numberTracker = StringTracker()
	
	override func viewDidLoad() {
		// Set up the Vision request before letting ViewController set up the camera
		// so it exists when the first buffer is received.
		request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

		super.viewDidLoad()
	}
	
	// MARK: - Text recognition
	
	// The Vision recognition handler.
	func recognizeTextHandler(request: VNRequest, error: Error?) {
		var numbers = [String]()
		var redBoxes = [CGRect]() // Shows all recognized text lines.
		var greenBoxes = [CGRect]() // Shows words that might be serials.
		
		guard let results = request.results as? [VNRecognizedTextObservation] else {
			return
		}
		
		let maximumCandidates = 1
		
		for visionResult in results {
			guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
			
			// Draw red boxes around any detected text and green boxes around
			// any detected phone numbers. The phone number may be a substring
			// of the visionResult. If it's a substring, draw a green box around
			// the number and a red box around the full string. If the number
			// covers the full result, only draw the green box.
			var numberIsSubstring = true
			
			if let result = candidate.string.extractPhoneNumber() {
				let (range, number) = result
				// The number might not cover full visionResult. Extract the bounding
				// box of the substring.
				if let box = try? candidate.boundingBox(for: range)?.boundingBox {
					numbers.append(number)
					greenBoxes.append(box)
					numberIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
				}
			}
			if numberIsSubstring {
				redBoxes.append(visionResult.boundingBox)
			}
		}
		
		// Log any found numbers.
		numberTracker.logFrame(strings: numbers)
		show(boxGroups: [(color: .red, boxes: redBoxes), (color: .green, boxes: greenBoxes)])
		
		// Check if there are any temporally stable numbers.
		if let sureNumber = numberTracker.getStableString() {
			showString(string: sureNumber)
			numberTracker.reset(string: sureNumber)
		}
	}
	
	override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
			// Configure for running in real time.
			request.recognitionLevel = .fast
            // Language correction doesn't help in recognizing phone numbers and also
            // slows recognition.
			request.usesLanguageCorrection = false
			// Only run on the region of interest for maximum speed.
			request.regionOfInterest = regionOfInterest
			
			let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
			do {
				try requestHandler.perform([request])
			} catch {
				print(error)
			}
		}
	}
	
	// MARK: - Bounding box drawing
	
	// Draw a box on the screen, which must be done the main queue.
	var boxLayer = [CAShapeLayer]()
	func draw(rect: CGRect, color: CGColor) {
		let layer = CAShapeLayer()
		layer.opacity = 0.5
		layer.borderColor = color
		layer.borderWidth = 1
		layer.frame = rect
		boxLayer.append(layer)
		previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
	}
	
	// Remove all drawn boxes. Must be called on main queue.
	func removeBoxes() {
		for layer in boxLayer {
			layer.removeFromSuperlayer()
		}
		boxLayer.removeAll()
	}
	
	typealias ColoredBoxGroup = (color: UIColor, boxes: [CGRect])
	
	// Draws groups of colored boxes.
	func show(boxGroups: [ColoredBoxGroup]) {
		DispatchQueue.main.async {
			let layer = self.previewView.videoPreviewLayer
			self.removeBoxes()
			for boxGroup in boxGroups {
				let color = boxGroup.color
				for box in boxGroup.boxes {
					let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
                    self.draw(rect: rect, color: color.cgColor)
				}
			}
		}
	}
}
