/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The UICollectionViewCell subclass for displaying photos.
*/

import UIKit

class PhotoCell: UICollectionViewCell {
    let photoView = UIImageView()
    static let reuseIdentifier = "cell-reuse-identifier"

    #if targetEnvironment(macCatalyst) // Cell selection feedback for Mac Catalyst only.
    override var isSelected: Bool {
        didSet {
            self.contentView.backgroundColor = self.isSelected ? UIColor.lightGray : nil
        }
    }
    #endif
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    func configure() {
        photoView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(photoView)
        let inset = 10.0
        NSLayoutConstraint.activate([
            photoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            photoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            photoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset),
            photoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset)
        ])
    }
    
}
