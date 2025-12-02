/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of reusable views and configurations for the custom MSSticker collection.
*/
import UIKit
import Messages

class TitleSupplementaryView: UICollectionReusableView {
    let label = UILabel()
    static let reuseIdentifier = "title-supplementary-reuse-identifier"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}

extension TitleSupplementaryView {
    func configure() {
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .natural
        label.textColor = .cornflowerBlue
        let inset = CGFloat(8)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
        label.font = UIFont.preferredFont(forTextStyle: .title3)
    }
}

class TextSupplementaryView: UICollectionReusableView {
    let field = CustomField()
    static let reuseIdentifier = "text-supplementary-reuse-identifier"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}

extension TextSupplementaryView {
    func configure() {
        field.translatesAutoresizingMaskIntoConstraints = false
        addSubview(field)
        field.adjustsFontForContentSizeCategory = true
        field.attributedPlaceholder = NSAttributedString(
            string: "Type a Sticker",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.cornflowerBlue])
        let inset = CGFloat(8)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            field.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            field.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
        field.font = UIFont.preferredFont(forTextStyle: .title3)
        field.placeholder = "Type a Sticker"
        field.layer.borderWidth = 1.0
        field.layer.borderColor = UIColor.cornflowerBlue.cgColor
    }
}

class CustomField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 8, dy: 8)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 8, dy: 8)
    }
}

class PictureSupplementaryView: UICollectionReusableView {
    let button = UIButton()
    static let reuseIdentifier = "picture-supplementary-reuse-identifier"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
}

extension PictureSupplementaryView {
    func configure() {
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.setTitle("Pick a Picture", for: .normal)
        button.backgroundColor = .cornflowerBlue
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.borderWidth = 0.1
        button.layer.cornerRadius = 12
        let inset = CGFloat(8)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            button.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset)
        ])
    }
}

struct CustomContentConfiguration: UIContentConfiguration, Hashable {
    var sticker: MSSticker? = nil
    
    func makeContentView() -> UIView & UIContentView {
        return CustomContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

class CustomContentView: UIView, UIContentView {
    
    private let stickerView = MSStickerView()
    
    // Set up the internal view and apply the custom configuration.
    init(configuration: CustomContentConfiguration) {
        super.init(frame: .zero)
        setupInternalViews()
        apply(configuration: configuration)
    }
    
    private func setupInternalViews() {
        stickerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stickerView)
        NSLayoutConstraint.activate([
            stickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickerView.topAnchor.constraint(equalTo: topAnchor),
            stickerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private var appliedConfiguration = CustomContentConfiguration()
    
    // Apply the custom configuration.
    private func apply(configuration: CustomContentConfiguration) {
        guard appliedConfiguration != configuration else { return }
        appliedConfiguration = configuration
        stickerView.sticker = appliedConfiguration.sticker
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var configuration: UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let newConfig = newValue as? CustomContentConfiguration else { return }
            apply(configuration: newConfig)
        }
    }
    
}
