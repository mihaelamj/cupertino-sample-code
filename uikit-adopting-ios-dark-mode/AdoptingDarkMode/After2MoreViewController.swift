/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller demonstrating typical creation of views: images, labels, blur, and vibrancy.
 This is the code after dark mode adoption has happened.
*/

import UIKit

class After2MoreViewController: UIViewController {

    override func loadView() {
        // Create our view controller's view.

        view = UIView()
        // DARK MODE ADOPTION: Changed from .white to a semantic color.
        view.backgroundColor = .systemBackground

        // Add various subviews, from top to bottom:
        // - Star image (our app's logo)
        // - Title label
        // - Background image view
        // - Visual effect view blurring that background image
        // - Visual effect view for vibrancy
        // - Vibrant label

        let starImageView = configureStarImageView()
        view.addSubview(starImageView)

        let titleLabel = configureTitleLabel()
        view.addSubview(titleLabel)

        let backgroundImageView = configureBackgroundImageView()
        view.addSubview(backgroundImageView)

        // DARK MODE ADOPTION: Changed from style: .light to an iOS 13
        // blur style, .systemThinMaterial, that has different appearances in light
        // and dark modes.
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = configureBlurView(blurEffect)
        view.addSubview(blurView)

        let vibrancyView = configureVibrancyView(blurEffect)
        blurView.contentView.addSubview(vibrancyView)

        let vibrantLabel = configureVibrantLabel()
        vibrancyView.contentView.addSubview(vibrantLabel)

        // Add constraints to put everything in the right place.
        setupConstraints()
    }

    let starImageView = UIImageView(image: #imageLiteral(resourceName: "StarImage"))

    func configureStarImageView() -> UIImageView {
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        // DARK MODE ADOPTION: Changed to a color, from the "After" asset catalog,
        // which has light and dark variants:
        starImageView.tintColor = UIColor(named: "LightAndDarkHeaderColor")
        return starImageView
    }

    let titleLabel = UILabel()

    func configureTitleLabel() -> UILabel {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle, compatibleWith: self.traitCollection)
        titleLabel.text = "Presented Content"
        // DARK MODE ADOPTION: Changed from .black to a semantic color:
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }

    let backgroundImageView = UIImageView()

    func configureBackgroundImageView() -> UIImageView {
        backgroundImageView.image = #imageLiteral(resourceName: "HeaderImage")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundImageView
    }

    let blurView = UIVisualEffectView()

    func configureBlurView(_ blurEffect: UIBlurEffect) -> UIVisualEffectView {
        blurView.effect = blurEffect
        blurView.preservesSuperviewLayoutMargins = true
        blurView.contentView.preservesSuperviewLayoutMargins = true
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }

    let vibrancyView = UIVisualEffectView()

    func configureVibrancyView(_ blurEffect: UIBlurEffect) -> UIVisualEffectView {
        // DARK MODE ADOPTION: Changed to use a specific iOS 13 vibrancy style:
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .secondaryLabel)
        vibrancyView.effect = vibrancyEffect
        vibrancyView.preservesSuperviewLayoutMargins = true
        vibrancyView.contentView.preservesSuperviewLayoutMargins = true
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        return vibrancyView
    }

    let vibrantLabel = UILabel()

    func configureVibrantLabel() -> UILabel {
        vibrantLabel.translatesAutoresizingMaskIntoConstraints = false
        vibrantLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle, compatibleWith: self.traitCollection)
        vibrantLabel.text = "Vibrant Label"
        return vibrantLabel
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            starImageView.topAnchor.constraint(equalToSystemSpacingBelow: view.layoutMarginsGuide.topAnchor, multiplier: 2),
            starImageView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 70),
            starImageView.heightAnchor.constraint(equalToConstant: 70),
            titleLabel.topAnchor.constraint(equalToSystemSpacingBelow: starImageView.bottomAnchor, multiplier: 2),
            titleLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            backgroundImageView.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 2),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.topAnchor.constraint(equalTo: backgroundImageView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: backgroundImageView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: backgroundImageView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: backgroundImageView.bottomAnchor),
            vibrancyView.topAnchor.constraint(equalTo: blurView.topAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            vibrantLabel.topAnchor.constraint(equalTo: vibrancyView.layoutMarginsGuide.topAnchor),
            vibrantLabel.leadingAnchor.constraint(equalTo: vibrancyView.layoutMarginsGuide.leadingAnchor)
            ])
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
