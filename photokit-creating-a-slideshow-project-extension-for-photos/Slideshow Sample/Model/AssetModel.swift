/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the asset model for the Photos project slideshow extension.
*/

import Foundation
import PhotosUI

struct AssetModel {
    var asset: PHAsset?
    let assetProjectElement: PHProjectAssetElement

    init(assetElement: PHProjectAssetElement) {
        assetProjectElement = assetElement
    }

    var preferredZoomRect: CGRect? {
        let sortedRois = assetProjectElement.regionsOfInterest.sorted { (roi1, roi2) -> Bool in
            return roi1.weight + roi1.quality < roi2.weight + roi2.quality
        }
        return sortedRois.last?.rect
    }
}

extension AssetModel {
    static func models(forProjectInfo projectInfo: PHProjectInfo,
                       project: PHProject,
                       library: PHPhotoLibrary) -> [AssetModel] {
        var assetModels = [AssetModel]()
        for section in projectInfo.sections {
            if let sectionContent = section.sectionContents.last {
                let modelsFromSectionContent = models(forSectionContent: sectionContent, photoLibrary: library)
                assetModels.append(contentsOf: modelsFromSectionContent)
            }
        }
        return assetModels
    }

    static func models(forSectionContent sectionContent: PHProjectSectionContent,
                       photoLibrary: PHPhotoLibrary) -> [AssetModel] {
        let assetElements = sectionContent.assetElements
        let cloudIdentifiers = assetElements.map { $0.cloudAssetIdentifier }
        var localIdentifiersToFetch = [String]()
        var filteredAssetElements = [PHProjectAssetElement]()
        
        if #available(macOSApplicationExtension 12, *) {
            let localIdentifierMappings = photoLibrary.localIdentifierMappings(for: cloudIdentifiers)
            var index = 0
            for (cloudIdentifier, result) in localIdentifierMappings {
                switch result {
                case let .success(localIdentifier):
                    localIdentifiersToFetch.append(localIdentifier)
                    filteredAssetElements.append(assetElements[index])
                case let .failure(error as PHPhotosError):
                    // Add real error handling code.
                    switch error.code {
                    case .identifierNotFound:
                        print("Failed to find local identifier for \(cloudIdentifier) \(error)")
                    case .multipleIdentifiersFound:
                        let multiple = error.userInfo[PHLocalIdentifiersErrorKey] as? [String] ?? []
                        print("Found multiple matching local identifiers for \(cloudIdentifier): \(multiple)")
                    default:
                        print("Error occured looking up local identifier for \(cloudIdentifier) \(error)")
                    }
                case let .failure(error):
                    print("Unexpected error looking up local identifier for \(cloudIdentifier) \(error)")
                }
                index += 1
            }
        } else {
            let localIdentifiers = photoLibrary.localIdentifiers(for: cloudIdentifiers)
            for (index, localIdentifier) in localIdentifiers.enumerated() {
                guard localIdentifier != PHLocalIdentifierNotFound && index < assetElements.count else {
                    continue
                }
                localIdentifiersToFetch.append(localIdentifier)
                filteredAssetElements.append(assetElements[index])
            }
        }

        var models = [AssetModel]()
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiersToFetch, options: nil)
        fetchResult.enumerateObjects { (asset, index, _) in
            let assetElement = filteredAssetElements[index]
            var model = AssetModel(assetElement: assetElement)
            model.asset = asset
            models.append(model)
        }
        return models
    }
}

extension PHProjectSectionContent {
    var assetElements: [PHProjectAssetElement] {
        var assetElements = [PHProjectAssetElement]()
        for element in elements {
            if let assetElement = element as? PHProjectAssetElement {
                assetElements.append(assetElement)
            }
        }
        return assetElements
    }
}
