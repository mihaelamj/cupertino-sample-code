/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Logic that renders a chunk of text in a view.
*/

import Cocoa

class TextLayoutFragmentView: NSView {
    let layoutFragment: NSTextLayoutFragment!
    
    override var isFlipped: Bool {
        return true
    }
    
    var renderingSurfaceBounds: CGRect {
        return layoutFragment.renderingSurfaceBounds
    }
    
    required init?(coder: NSCoder) {
        layoutFragment = nil
        super.init(coder: coder)
        setupView()
    }

    init(element: NSTextLayoutFragment) {
        layoutFragment = element
        super.init(frame: layoutFragment.layoutFragmentFrame)
        setupView()
    }
    
    func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    func draw(_ context: CGContext) {
        layoutFragment.draw(at: layoutFragment.layoutFragmentFrame.origin, in: context)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if frame != layoutFragment.layoutFragmentFrame {
            setFrameOrigin(layoutFragment.layoutFragmentFrame.origin)
        }

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            fatalError("Cannot get graphics context")
        }

        layoutFragment.draw(at: .zero, in: ctx)
    }
}
