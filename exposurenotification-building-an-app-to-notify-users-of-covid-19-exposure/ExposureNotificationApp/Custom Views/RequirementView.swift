/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for statements required to be made.
*/

import UIKit

class RequirementView: UIView {
    
    init(text: String) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        layer.cornerRadius = 13.0
        layer.cornerCurve = .continuous
        
        let titleLabel = UILabel()
        titleLabel.text = "Required To Be Stated By App"
        titleLabel.numberOfLines = 0
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityTraits = .header

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.numberOfLines = 0
        textLabel.font = .preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, textLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8.0
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.0),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16.0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16.0)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
