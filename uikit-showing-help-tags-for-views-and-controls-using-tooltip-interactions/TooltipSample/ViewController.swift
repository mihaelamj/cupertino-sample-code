/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller of the app.
*/

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var containerStackView: UIStackView!
    @IBOutlet var textView: TextViewWithTooltip!
    
    /// - Tag: labelWithTooltip
    lazy var labelWithTooltip: UILabel = {
        let label = UILabel()
        label.text = "Hover the pointer over this label to see its tooltip."
        label.numberOfLines = 0
        
        let tooltipInteraction = UIToolTipInteraction(defaultToolTip: "The label's tooltip.")
        label.addInteraction(tooltipInteraction)
        
        return label
    }()
    
    /// - Tag: buttonWithTooltip
    lazy var buttonWithTooltip: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Buy"
        configuration.subtitle = "Only $9.99"
        configuration.titleAlignment = .center
        
        let action = UIAction { _ in print("Thank you for your purchase.") }

        let button = UIButton(configuration: configuration, primaryAction: action)
        button.toolTip = "Click to buy this item. You'll have a chance to change your mind before confirming your purchase."
        button.preferredBehavioralStyle = .pad
        
        return button
    }()
    
    var cartItemCount = 0
    
    /// - Tag: shoppingCartButtonWithTooltip
    lazy var shoppingCartButtonWithTooltip: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Add to Cart"
        configuration.image = UIImage(systemName: "cart.circle")
        configuration.imagePlacement = NSDirectionalRectEdge.leading
        configuration.imagePadding = 4
        
        let action = UIAction { [unowned self] _ in self.cartItemCount += 1 }
        
        let button = UIButton(configuration: configuration, primaryAction: action)
        button.toolTip = "Click to add the item to your cart. Your cart is empty."
        button.toolTipInteraction?.delegate = self
        
        return button
    }()
    
    /// - Tag: viewWithDefaultTooltip
    lazy var viewWithDefaultTooltip: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGreen
        view.addText("Hover the pointer over this view to see its default tooltip.")

        let tooltipInteraction = UIToolTipInteraction(defaultToolTip: "The default tooltip for the view.")
        view.addInteraction(tooltipInteraction)

        return view
    }()
    
    /// - Tag: viewWithBackgroundColorTooltip
    lazy var viewWithBackgroundColorTooltip: UIView = {
        let view = ViewWithBackgroundColorTooltip()
        view.backgroundColor = UIColor.systemYellow
        view.addText("Hover the pointer over this view to see the name of the view's background color.")

        let tooltipInteraction = UIToolTipInteraction()
        tooltipInteraction.delegate = view
        view.addInteraction(tooltipInteraction)
        
        return view
    }()
    
    lazy var viewWithTooltipRegion: UIView = {
        let view = ViewWithTooltipRegion()
        view.backgroundColor = UIColor.systemTeal
        view.addText("Hover the pointer over this view's top or bottom regions to see a tooltip.")
        
        let tooltipInteraction = UIToolTipInteraction()
        tooltipInteraction.delegate = view
        view.addInteraction(tooltipInteraction)
        
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerStackView.addArrangedSubview(viewWithDefaultTooltip)
        containerStackView.addArrangedSubview(labelWithTooltip)
        containerStackView.addArrangedSubview(buttonWithTooltip)
        containerStackView.addArrangedSubview(viewWithBackgroundColorTooltip)
        containerStackView.addArrangedSubview(shoppingCartButtonWithTooltip)
        containerStackView.addArrangedSubview(viewWithTooltipRegion)
        
        let tooltipInteraction = UIToolTipInteraction()
        tooltipInteraction.delegate = textView
        textView.addInteraction(tooltipInteraction)
    }
    
}

extension ViewController: UIToolTipInteractionDelegate {
    
    /// - Tag: shoppingCartButtonWithTooltipDelegate
    func toolTipInteraction(_ interaction: UIToolTipInteraction, configurationAt point: CGPoint) -> UIToolTipConfiguration? {
        
        let text: String
        switch cartItemCount {
        case 0:
            text = "Click to add the item to your cart. Your cart is empty."
        case 1:
            text = "Click to add the item to your cart. Your cart contains \(cartItemCount) item."
        default:
            text = "Click to add the item to your cart. Your cart contains \(cartItemCount) items."
        }
        
        return UIToolTipConfiguration(toolTip: text)
    }
    
}

extension UIView {
    
    func addText(_ text: String) {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = text
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}
