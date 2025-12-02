/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The control for adjusting the document text size.
*/

import UIKit

class TextSizeSlider: UISlider {
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        
#if !targetEnvironment(macCatalyst)
        minimumValueImage = UIImage(systemName: "textformat.size.smaller")
        maximumValueImage = UIImage(systemName: "textformat.size.larger")
#endif
        
        widthAnchor.constraint(equalToConstant: 120.0).isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func tapped(_ gesture: UITapGestureRecognizer) {
        setValue(1.0, animated: true)
        sendActions(for: .valueChanged)
    }
}
