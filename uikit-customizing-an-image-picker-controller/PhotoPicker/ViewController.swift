/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller for this sample app.
*/

import UIKit
import AVFoundation

class APLViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	@IBOutlet var imageView: UIImageView?
	@IBOutlet var cameraButton: UIBarButtonItem?
	@IBOutlet var overlayView: UIView?
	
	/// The camera controls in the overlay view.
	@IBOutlet var takePictureButton: UIBarButtonItem?
	@IBOutlet var startStopButton: UIBarButtonItem?
	@IBOutlet var delayedPhotoButton: UIBarButtonItem?
	@IBOutlet var doneButton: UIBarButtonItem?

    /// An image picker controller instance.
	var imagePickerController = UIImagePickerController()
	
	var cameraTimer = Timer()
    /// An array for storing captured images to display.
	var capturedImages = [UIImage]()
	
	// MARK: - View Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()

		imagePickerController.modalPresentationStyle = .currentContext
        /*
         Assign a delegate for the image picker. The delegate receives
         notifications when the user picks an image or movie, or exits the
         picker interface. The delegate also decides when to dismiss the picker
         interface.
        */
		imagePickerController.delegate = self

        /*
         This app requires use of the device's camera. The app checks for device
         availability using the `isSourceTypeAvailable` method. If the
         camera isn't available, the app removes the camera button from the
         custom user interface.
         */
		if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
			toolbarItems = self.toolbarItems?.filter { $0 != cameraButton }
		}
    }

	func finishAndUpdate() {
		dismiss(animated: true, completion: { [weak self] in
			guard let self = self else {
				return
			}
			
			if !self.capturedImages.isEmpty {
				if self.capturedImages.count == 1 {
					// The camera took a single picture.
					self.imageView?.image = self.capturedImages[0]
				} else {
                    /*
                     The camera captured multiple pictures. Cycle through the
                     captured frames in the view, showing each one for 5 seconds
                     in an animation.
                    */
					self.imageView?.animationImages = self.capturedImages
                    // Show each captured photo for 5 seconds.
					self.imageView?.animationDuration = 5
                    // Animate the images indefinitely (show all photos).
					self.imageView?.animationRepeatCount = 0
					self.imageView?.startAnimating()
				}
				
				/*
                 Clear the array of captured images to start taking pictures
                 again.
                */
				self.capturedImages.removeAll()
			}
		})
	}
	
	// MARK: - Toolbar Actions
	
    /// - Tag: CameraSourceType
	@IBAction func showImagePickerForCamera(_ sender: UIBarButtonItem) {
		let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		
		if authStatus == AVAuthorizationStatus.denied {
			// The system denied access to the camera. Alert the user.

			/*
             The user previously denied access to the camera. Tell the user this
             app requires camera access.
            */
			let alert = UIAlertController(title: "Unable to access the Camera",
										  message: "To turn on camera access, choose Settings > Privacy > Camera and turn on Camera access for this app.",
										  preferredStyle: UIAlertController.Style.alert)
			
			let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
			alert.addAction(okAction)
			
			let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
				// Take the user to the Settings app to change permissions.
				guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
				if UIApplication.shared.canOpenURL(settingsUrl) {
					UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
						// The resource finished opening.
					})
				}
			})
			alert.addAction(settingsAction)
			
			present(alert, animated: true, completion: nil)
		} else if authStatus == AVAuthorizationStatus.notDetermined {
            /*
             The user never granted or denied permission for media capture with
             the camera. Ask for permission.

             Note: The app must provide a `Privacy - Camera Usage Description`
             key in the Info.plist with a message telling the user why the app
             is requesting access to the device’s camera. See this app's
             Info.plist for such an example usage description.
            */
			AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
				if granted {
					DispatchQueue.main.async {
						self.showImagePicker(sourceType: UIImagePickerController.SourceType.camera, button: sender)
					}
				}
			})
		} else {
            /*
             The user granted permission to access the camera. Present the
             picker for capture.

             Set the image picker `sourceType` property to
             `UIImagePickerController.SourceType.camera` to configure the picker
             for media capture instead of browsing saved media.
            */
			showImagePicker(sourceType: UIImagePickerController.SourceType.camera, button: sender)
		}
	}

    /**
    Set `sourceType` to `UIImagePickerController.SourceType.photoLibrary` to
    present a browser that provides access to all the photo albums on the
    device, including the Camera Roll album.
    */
	@IBAction func showImagePickerForPhotoPicker(_ sender: UIBarButtonItem) {
		showImagePicker(sourceType: UIImagePickerController.SourceType.photoLibrary, button: sender)
	}

	func showImagePicker(sourceType: UIImagePickerController.SourceType, button: UIBarButtonItem) {
        // Stop animating the images in the view.
		if (imageView?.isAnimating)! {
			imageView?.stopAnimating()
		}
		if !capturedImages.isEmpty {
			capturedImages.removeAll()
		}

		imagePickerController.sourceType = sourceType
		imagePickerController.modalPresentationStyle =
			(sourceType == UIImagePickerController.SourceType.camera) ?
				UIModalPresentationStyle.fullScreen : UIModalPresentationStyle.popover
		
		let presentationController = imagePickerController.popoverPresentationController
        // Display a popover from the UIBarButtonItem as an anchor.
		presentationController?.barButtonItem = button
		presentationController?.permittedArrowDirections = UIPopoverArrowDirection.any

		if sourceType == UIImagePickerController.SourceType.camera {
			/*
             The user tapped the camera button in the app's interface which
             specifies the device’s built-in camera as the source for the image
             picker controller.
            */

            /*
             Hide the default controls.
             This sample provides its own custom controls for still image
             capture in an overlay view.
            */
			imagePickerController.showsCameraControls = false

            /*
             Apply the overlay view. This view contains a toolbar with custom
             controls for capturing still images in various ways.
            */
			overlayView?.frame = (imagePickerController.cameraOverlayView?.frame)!
			imagePickerController.cameraOverlayView = overlayView
		}
		
        /*
         The creation and configuration of the camera or media browser
         interface is now complete.

         Asynchronously present the picker interface using the
         `present(_:animated:completion:)` method.
        */
		present(imagePickerController, animated: true, completion: {
			// The block to execute after the presentation finishes.
		})
	}
	
	// MARK: - Camera View Actions
	
	@IBAction func done(_ sender: UIBarButtonItem) {
		if cameraTimer.isValid {
			cameraTimer.invalidate()
		}
		finishAndUpdate()
	}
    /// - Tag: TakePicture
	@IBAction func takePhoto(_ sender: UIBarButtonItem) {
		imagePickerController.takePicture()
	}

    /// - Tag: DelayedPhoto
	@IBAction func delayedTakePhoto(_ sender: UIBarButtonItem) {
        /*
         Disable the photo controls during the delay time period.
         The code in the timer completion block below captures a still image
         when the delay period expires, and enables the controls.
        */
		doneButton?.isEnabled = false
		takePictureButton?.isEnabled = false
		delayedPhotoButton?.isEnabled = false
		startStopButton?.isEnabled = false
		
		let fireDate = Date(timeIntervalSinceNow: 5)
		cameraTimer = Timer(fire: fireDate, interval: 1.0, repeats: false, block: { timer in
            // The time interval expired. Capture a still image.
			self.imagePickerController.takePicture()

            // Enable the delayed photos controls.
			self.doneButton?.isEnabled = true
			self.takePictureButton?.isEnabled = true
			self.delayedPhotoButton?.isEnabled = true
			self.startStopButton?.isEnabled = true
		})
		RunLoop.main.add(cameraTimer, forMode: RunLoop.Mode.default)
	}

    /// - Tag: PhotoAtInterval
	@IBAction func startTakingPicturesAtIntervals(_ sender: UIBarButtonItem) {
		// Start the timer to take a photo every 5 seconds.

		startStopButton?.title = NSLocalizedString("Stop", comment: "Title for overlay view controller start/stop button")
		startStopButton?.action = #selector(stopTakingPicturesAtIntervals)
		
        // Enable these buttons while capturing photos.
		doneButton?.isEnabled = false
		delayedPhotoButton?.isEnabled = false
		takePictureButton?.isEnabled = false

		// Start taking pictures.
		cameraTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
			self.imagePickerController.takePicture()
		}
	}

    /// - Tag: StopTakingPictures
	@IBAction func stopTakingPicturesAtIntervals(_ sender: UIBarButtonItem) {
		// Stop and reset the timer.
		cameraTimer.invalidate()

		finishAndUpdate()
		
		// Make these buttons available again.
		self.doneButton?.isEnabled = true
		self.takePictureButton?.isEnabled = true
		self.delayedPhotoButton?.isEnabled = true
		
		startStopButton?.title = NSLocalizedString("Start", comment: "Title for overlay view controller start/stop button")
		startStopButton?.action = #selector(startTakingPicturesAtIntervals)
	}
	
	// MARK: - UIImagePickerControllerDelegate
    /**
    You must implement the following methods that conform to the
    `UIImagePickerControllerDelegate` protocol to respond to user interactions
    with the image picker.

    When the user taps a button in the camera interface to accept a newly
    captured picture, the system notifies the delegate of the user’s choice by
    invoking the `imagePickerController(_:didFinishPickingMediaWithInfo:)`
    method. Your delegate object’s implementation of this method can perform
    any custom processing on the passed media, and should dismiss the picker.
    The delegate methods are always responsible for dismissing the picker when
    the operation completes.
    */
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        guard let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage else {
            return
        }
        capturedImages.append(image)

		if !cameraTimer.isValid {
            /*
             The user pressed either the Stop button while taking pictures or
             the Done button in the overlay view. The action methods for these
             controls invalidate the timer.

             Dismiss the view controller for capturing pictures.

             Cycle through any captured frames and display each one in the view
             for 5 seconds in an animation.
            */
			finishAndUpdate()
		}
	}

    /**
    If the user cancels the operation, the system invokes the delegate's
    `imagePickerControllerDidCancel(_:)` method, and you should dismiss the
    picker.
    */
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: {
        /*
         The dismiss method calls this block after dismissing the image picker
         from the view controller stack. Perform any additional cleanup here.
        */
		})
	}
}

// MARK: - Utilities
private func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) })
}

private func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
