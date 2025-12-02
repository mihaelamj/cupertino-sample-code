/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that presents a circular text view.
*/

import UIKit

class CircleTextViewController: BaseViewController {
    var ellipsisGlyphRange: NSRange?
    var flexibleSpaceGlyphRange: NSRange?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Create a UITextView instance with a custom text container.
        //
        let textContainer = CircleTextContainer(size: .zero)
        textContainer.widthTracksTextView = true

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textView = UITextView(frame: CGRect.zero, textContainer: textContainer)
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.keyboardDismissMode = .interactive
        view.addSubview(textView)
                
        // Set up Auto Layout constraints.
        //
        textView.translatesAutoresizingMaskIntoConstraints = false
        let safeAreaGuide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor)
        ])
        
        tabBarController?.delegate = self
    }
    
    // Trigger glyph substitution when UIKit finishes laying out the text view
    // and the text view isn't the first responder.
    //
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !textView.isFirstResponder {
            triggerGlyphSubstitutionIfNeeded()
        }
    }
    
    // Restore substituted glyphs when the size is about to change. This happens when the device rotates.
    // UIKit calls viewDidLayoutSubviews() after the size changes, which triggers glyph substitution, if necessary.
    //
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if !textView.isFirstResponder {
            restoreSubstitutedGlyphsIfNeeded()
        }
    }
    
    // Set up the delegates when the view is about to be onscreen.
    //
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.layoutManager.delegate = self
        textView.delegate = self
    }
    
    // Clear the delegates to avoid running the delegate methods unnecessarily
    // after the view is offscreen.
    //
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        textView.layoutManager.delegate = nil
        textView.delegate = nil
    }
}

// Restore substituted glyphs when an editing session is about to begin,
// and trigger glyph substitution after the editing session finishes.
//
extension CircleTextViewController: UITextViewDelegate {
        
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        restoreSubstitutedGlyphsIfNeeded()
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        triggerGlyphSubstitutionIfNeeded()
    }
}

// Restore substituted glyphs when the UI is about to switch to this view controller,
// and trigger glyph substitution after the UI switching finishes.
// This is necessary because users may have changed the text storage.
//
extension CircleTextViewController: UITabBarControllerDelegate {
        
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController === self && viewController !== tabBarController.selectedViewController {
            restoreSubstitutedGlyphsIfNeeded()
        }
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController === self && ellipsisGlyphRange == nil {
            triggerGlyphSubstitutionIfNeeded()
        }
    }
}

