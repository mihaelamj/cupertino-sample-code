/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom UICollectionViewFlowLayout subclass that lays out the image thumbnails.
*/

import UIKit

// This is a custom flow layout to align the image items to the left and use fixed spacing between items.
// It is a specific-purpose layout for aligning the items quickly.
//
class ImageItemsFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let defaultAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        // UICollectionViewFlowLayout flows the items sequentially and lays out the items in the correct rows.
        // Adjust the item’s originX to make it align.
        //
        var finalLayoutAttributes = [UICollectionViewLayoutAttributes]()
        var originX = sectionInset.left, maxY = sectionInset.top
        
        for attribute in defaultAttributes {
            if let newAttribute = attribute.copy() as? UICollectionViewLayoutAttributes {
                if newAttribute.frame.origin.y >= maxY {
                    originX = sectionInset.left
                }
                newAttribute.frame.origin.x = originX
                finalLayoutAttributes.append(newAttribute)

                originX += attribute.frame.width + minimumInteritemSpacing
                maxY = max(attribute.frame.maxY, maxY)
            }
        }
        return finalLayoutAttributes
    }
}
