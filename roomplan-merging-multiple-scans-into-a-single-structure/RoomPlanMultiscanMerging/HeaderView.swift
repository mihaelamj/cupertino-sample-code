/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sample app's main view.
*/

import UIKit

/// A view for a custom table header.
class HeaderView: UIView {

    /// A label for a title.
    private var titleLabel = UILabel()
    
    /// A text reference for a title.
    private var title: String!

    /// Creates a header view for the given frame and text.
    public init(frame: CGRect, title: String) {
        super.init(frame: frame)
        self.title = title
        self.setupView()
    }

    /// Defines a required, but unimplemented, initializer.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the header view.
    public func setupView() {
        addSubview(titleLabel)

        // Define the header view's text and font style.
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 35)
        titleLabel.textColor = .black

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 12).isActive = true
    }

}
