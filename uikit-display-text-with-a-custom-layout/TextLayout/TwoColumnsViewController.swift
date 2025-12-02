/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that implements a two-column text layout.
*/

import UIKit

class TwoColumnsViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let firstTextContainer = NSTextContainer()
        firstTextContainer.widthTracksTextView = true
        firstTextContainer.heightTracksTextView = true
        
        let secondTextContainer = NSTextContainer()
        secondTextContainer.widthTracksTextView = true
        secondTextContainer.heightTracksTextView = true
        secondTextContainer.lineBreakMode = .byTruncatingTail

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(firstTextContainer)
        layoutManager.addTextContainer(secondTextContainer)
        
        textStorage.addLayoutManager(layoutManager)
        
        let firstTextView = UITextView(frame: .zero, textContainer: firstTextContainer)
        firstTextView.isScrollEnabled = false
        view.addSubview(firstTextView)
        
        let secondTextView = UITextView(frame: .zero, textContainer: secondTextContainer)
        secondTextView.isScrollEnabled = false
        view.addSubview(secondTextView)

        // Set up Auto Layout constraints.
        //
        firstTextView.translatesAutoresizingMaskIntoConstraints = false
        secondTextView.translatesAutoresizingMaskIntoConstraints = false
        let safeAreaGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            firstTextView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor),
            firstTextView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            firstTextView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor),

            secondTextView.leadingAnchor.constraint(equalTo: firstTextView.trailingAnchor,
                                                    constant: 10),
            secondTextView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor),
            secondTextView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            secondTextView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor),
            
            secondTextView.widthAnchor.constraint(equalTo: firstTextView.widthAnchor)
        ])
        
        textView = secondTextView
    }
}
