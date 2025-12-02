/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Values and functions that the app defines and uses for its layout.
*/

import SwiftUI

struct Constants {
    // MARK: App-wide constants
    
    static let cornerRadius: CGFloat = 15.0
    static let leadingContentInset: CGFloat = 26.0
    static let matchesNavigationTitlePadding: CGFloat = 26.0
    static let standardPadding: CGFloat = 14.0
    static let safeAreaPadding: CGFloat = 30.0
    static let titleTopPadding: CGFloat = 8.0

    // MARK: Collection grid constants
    
    static let collectionGridSpacing: CGFloat = 14.0
    static var collectionGridWidth: CGFloat {
        return landmarkGridWidth
    }
    static let collectionGridItemMinSize: CGFloat = 160.0
    static let collectionGridItemMaxSize: CGFloat = 300.0
    static let collectionGridItemCornerRadius: CGFloat = 8.0
    
    // MARK: Collection detail constants
    
    static let textEditorHeight: CGFloat = 88.0
    static let minimumLandmarkWidth: CGFloat = 120.0
    static let landmarkGridPadding: CGFloat = 8.0
    static var landmarkGridWidth: CGFloat {
        return minimumLandmarkWidth * 4.0 + (5 * landmarkGridPadding)
    }
    
    static let collectionFormMinWidth: CGFloat = 320
    static let collectionFormIdealWidth: CGFloat = 600
    static let collectionFormMaxWidth: CGFloat = 800
    
    // MARK: Landmark grid constants
    
    static let landmarkGridSpacing: CGFloat = 14.0
    static let landmarkGridItemMinSize: CGFloat = 160.0
    static let landmarkGridItemMaxSize: CGFloat = 240.0

    // MARK: Landmark detail constants
    
    static let mapAspectRatio: CGFloat = 1.2
    
    // MARK: Landmark featured item constants
    
    static let learnMorePadding: CGFloat = 6.0
    static let learnMoreCornerRadius: CGFloat = 12.0
    static let learnMoreBottomPadding: CGFloat = 40.0
    
    // MARK: Landmark list constants
    
    static let landmarkListItemAspectRatio: CGFloat = 1.4
    static let landmarkListPercentOfHeight: CGFloat = 0.3

    // MARK: Landmark selection constants
    
    static let landmarkSelectionImageSize: CGSize = CGSize(width: 60.0, height: 40.0)
    static let landmarkSelectionImageCornerRadius: CGFloat = 8.0
}
