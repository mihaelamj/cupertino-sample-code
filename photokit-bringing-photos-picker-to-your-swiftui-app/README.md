# Bringing Photos picker to your SwiftUI app
Select media assets by using a Photos picker view that SwiftUI provides.

## Overview
This sample shows how to use the SwiftUI Photos picker to browse and select a photo from your photo library. The app displays an interface that allows you to fill in customer profile details, and includes a button to select a photo from the Photos library. The sample explores how to retrieve a SwiftUI image by using [`Transferable`][1] — a new SwiftUI protocol you use to move data.

- Note: This sample code project is associated with WWDC22 session [10023: What’s new in the Photos picker](https://developer.apple.com/wwdc22/10023).


## Configure the Sample Code Project
Before you run the sample code project in Xcode, ensure you’re using iOS 16 or later, watchOS 9 or later, macOS 13 or later. 

You must use a physical device when building the watchOS target in Xcode.

## Add a Photos picker view
To display the picker, the sample adds a [`PhotosPicker`][2] view as an overlay to a profile image. The view provides a label that describes the action of choosing an item from the photo library. The sample displays assets that match the image type. In iOS 16 or later, [`PHPickerFilter`][3] contains new filters for [`bursts`][4], [`cinematicVideos`][5], and [`depthEffectPhotos`][6].

``` swift
CircularProfileImage(imageState: viewModel.imageState)
	.overlay(alignment: .bottomTrailing) {
		PhotosPicker(selection: $viewModel.imageSelection,
					 matching: .images,
					 photoLibrary: .shared()) {
			Image(systemName: "pencil.circle.fill")
				.symbolRenderingMode(.multicolor)
				.font(.system(size: 30))
				.foregroundColor(.accentColor)
		}
		.buttonStyle(.borderless)
	}
```

## Load an image from the selection
The sample contains an [`ObservedObject`][7] that contains the selection. The selection only contains a placeholder object. Some large files may take a long time to download, so the sample shows an inline loading indicator instead of an indicator that blocks execution.

``` swift
@Published var imageSelection: PhotosPickerItem? = nil {
    didSet {
        if let imageSelection {
            let progress = loadTransferable(from: imageSelection)
            imageState = .loading(progress)
        } else {
            imageState = .empty
        }
    }
}
```

To load the asset data, [`PhotosPickerItem`][8] adopts [`Transferable`][9]. The sample attempts to retrieve the SwiftUI [`Image`][10] from the item. A failure can occur when the system attempts to retrieve the data. For example, if the picker tries to download data from iCloud Photos without a network connection.

``` swift
private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
    return imageSelection.loadTransferable(type: ProfileImage.self) { result in
        DispatchQueue.main.async {
            guard imageSelection == self.imageSelection else {
                print("Failed to get the selected item.")
                return
            }
            switch result {
            case .success(let profileImage?):
                self.imageState = .success(profileImage.image)
            case .success(nil):
                self.imageState = .empty
            case .failure(let error):
                self.imageState = .failure(error)
            }
        }
    }
}
```

In advanced data transfer cases, an app can control the type of data to load by defining a custom model object that conforms to the `Transferable` protocol. The sample creates a model `ProfileImage` to handle loading a [`DataRepresentation`][12] of an image, and converts it to a `UIImage` or `NSImage`.

``` swift
struct ProfileImage: Transferable {
    let image: Image
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
        #if canImport(AppKit)
            guard let nsImage = NSImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(nsImage: nsImage)
            return ProfileImage(image: image)
        #elseif canImport(UIKit)
            guard let uiImage = UIImage(data: data) else {
                throw TransferError.importFailed
            }
            let image = Image(uiImage: uiImage)
            return ProfileImage(image: image)
        #else
            throw TransferError.importFailed
        #endif
        }
    }
}
```

When handling many items at the same time, or large assets, use [`FileTransferRepresentation`][13] to load assets as files and reduce memory usage. When loading assets as files, copy them to an app directory and remove them when they’re no longer needed.

[1]: https://developer.apple.com/documentation/coretransferable/transferable
[2]: https://developer.apple.com/documentation/photosui/photospicker
[3]: https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct
[4]: https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct/bursts
[5]: https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct/cinematicVideos
[6]: https://developer.apple.com/documentation/photosui/phpickerfilter-swift.struct/depthEffectPhotos
[7]: https://developer.apple.com/documentation/swiftui/observedobject
[8]: https://developer.apple.com/documentation/photosui/photospickeritem
[9]: https://developer.apple.com/documentation/coretransferable/transferable
[10]: https://developer.apple.com/documentation/swiftui/image
[11]: https://developer.apple.com/documentation/uikit/uiimage
[12]: https://developer.apple.com/documentation/coretransferable/datarepresentation
[13]: https://developer.apple.com/documentation/coretransferable/filerepresentation
