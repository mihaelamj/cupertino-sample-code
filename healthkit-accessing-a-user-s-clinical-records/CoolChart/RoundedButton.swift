/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A rounded button.
*/

import UIKit

/// A round UIButton, used for the 'Authorize' action.
class RoundedButton: UIButton {
    
    override var tintColor: UIColor! {
        didSet {
            backgroundColor = tintColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setTitleColor(.white, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        backgroundColor = tintColor
        layer.cornerRadius = 8
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setIconInLeft(spacing: CGFloat = 12) {
        let halfSpacing = spacing / 2
        titleEdgeInsets = UIEdgeInsets(top: 0, left: halfSpacing, bottom: 0, right: -halfSpacing)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -halfSpacing, bottom: 0, right: halfSpacing)
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? tintColor.withAlphaComponent(0.5) : tintColor
        }
    }
}
