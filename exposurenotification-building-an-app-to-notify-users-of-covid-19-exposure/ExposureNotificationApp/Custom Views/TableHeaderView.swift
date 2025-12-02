/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom table view header.
*/

import UIKit

class TableHeaderView: UITableViewHeaderFooterView {
    
    var headerText: String? {
        get {
            headerLabel.text
        }
        set {
            headerLabel.text = newValue
        }
    }
    
    var text: String? {
        get {
            label.text
        }
        set {
            label.text = newValue
        }
    }
    
    var buttonText: String? {
        get {
            button.title(for: .normal)
        }
        set {
            button.setTitle(newValue, for: .normal)
            button.isHidden = buttonText == nil
        }
    }
    
    var buttonAction: (() -> Void)?
    
    let headerLabel = UILabel()
    let label = UILabel()
    let button = Button(type: .system)
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        headerLabel.numberOfLines = 0
        headerLabel.font = .preferredFont(forTextStyle: .headline)
        headerLabel.adjustsFontForContentSizeCategory = true
        
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        
        button.isHidden = true
        button.titleLabel!.font = .preferredFont(forTextStyle: .body)
        button.addTarget(self, action: #selector(buttonTouchUpInside), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [headerLabel, label, button])
        stackView.axis = .vertical
        stackView.spacing = 8.0
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        preservesSuperviewLayoutMargins = true
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16.0),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16.0)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func buttonTouchUpInside() {
        buttonAction?()
    }
}
