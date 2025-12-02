/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for editing document content.
*/

import UIKit

class EditorView: UITextView {
    
    var fontScale = 1.0
    let fontScaleStep = 0.1
    let fontScaleRange = 0.5...1.5
    let defaultFontSize = 15.0
    let textSizeSlider = TextSizeSlider()
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        font = .monospacedSystemFont(ofSize: defaultFontSize, weight: .regular)
        backgroundColor = .clear
        indicatorStyle = .white
        textColor = .white
        alwaysBounceVertical = true
        self.textContainer.lineFragmentPadding = 0
        
        textSizeSlider.minimumValue = Float(fontScaleRange.lowerBound)
        textSizeSlider.maximumValue = Float(fontScaleRange.upperBound)
        textSizeSlider.value = 1.0
        textSizeSlider.addAction(UIAction { [unowned self] action in
            if let slider = action.sender as? UISlider {
                updateFontScale(CGFloat(slider.value))
            }
        }, for: .valueChanged)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textSizeMenu() -> UIMenu {
        return UIMenu(title: "Text Size", options: .displayInline, preferredElementSize: .small, children: [
            UIAction(title: "Decrease", image: UIImage(systemName: "minus.magnifyingglass"), attributes: .keepsMenuPresented) { [unowned self] _ in
                updateFontScale(fontScale - fontScaleStep)
            },
            UIAction(title: "Reset", image: UIImage(systemName: "1.magnifyingglass"), attributes: .keepsMenuPresented) { [unowned self] _ in
                updateFontScale(1.0)
            },
            UIAction(title: "Increase", image: UIImage(systemName: "plus.magnifyingglass"), attributes: .keepsMenuPresented) { [unowned self] _ in
                updateFontScale(fontScale + fontScaleStep)
            }
        ])
    }
    
    // MARK: Internal
    
    private func updateFontScale(_ scale: CGFloat) {
        fontScale = max(fontScaleRange.lowerBound, min(scale, fontScaleRange.upperBound))
        font = UIFont.monospacedSystemFont(ofSize: defaultFontSize * fontScale, weight: .regular)
    }
}
