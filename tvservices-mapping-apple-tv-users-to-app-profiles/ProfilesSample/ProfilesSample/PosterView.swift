/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that represents the content for the app.
*/

import UIKit

class PosterView: UIView {

    var color: UIColor {
        didSet {
            _updateBackground()
            _updateText()
        }
    }

    var symbol: String {
        didSet {
            _updateText()
        }
    }

    private let label: UILabel

    override init(frame: CGRect) {
        color = .white
        symbol = ""
        label = UILabel(frame: .zero)
        super.init(frame: frame)
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        _updateText()
    }

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    private func _updateText() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let (hue, saturation, brightness) = color.hsbComponents()
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(hue: hue, saturation: saturation, brightness: 0.2 * brightness, alpha: 0.5)
        shadow.shadowOffset = CGSize(width: 2.0, height: 2.0)
        shadow.shadowBlurRadius = 3.0

        let font = UIFont.preferredFont(forTextStyle: .title1).withSize((0.5 * frame.size.height).rounded(.toNearestOrAwayFromZero))
        label.attributedText = NSAttributedString(string: symbol, attributes: [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle,
            .shadow: shadow,
            .baselineOffset: (0.02 * frame.size.height).rounded(.toNearestOrAwayFromZero)
            ])

        setNeedsDisplay()
    }

    private func _updateBackground() {
        guard let layer = self.layer as? CAGradientLayer else { return }

        let (hue, saturation, brightness) = color.hsbComponents()
        let startPointColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
        let endPointColor = UIColor(hue: hue, saturation: saturation, brightness: 0.6 * brightness, alpha: 1.0)

        layer.colors = [startPointColor.cgColor, endPointColor.cgColor]
        layer.startPoint = CGPoint(x: 0.0, y: 0.0)
        layer.endPoint = CGPoint(x: 1.0, y: 1.0)
    }
}

extension UIColor {
    fileprivate func hsbComponents() -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        return (hue: hue, saturation: saturation, brightness: brightness)
    }
}
