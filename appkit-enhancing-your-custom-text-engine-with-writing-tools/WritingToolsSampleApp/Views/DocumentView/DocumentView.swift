/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation and declarations for the document view.
*/

import Cocoa

class DocumentView: NSView, @preconcurrency NSTextViewportLayoutControllerDelegate {
    // MARK: - Basic implementation
    var textLayoutManager: NSTextLayoutManager? {
        willSet {
            if let tlm = textLayoutManager {
                tlm.textViewportLayoutController.delegate = nil
            }
        }
        didSet {
            if let tlm = textLayoutManager {
                tlm.textViewportLayoutController.delegate = self
            }
            needsLayout = true
        }
    }
    
    var viewModel: DocumentViewModel
    
    private var boundsDidChangeObserver: NSObjectProtocol? = nil
    
    private let selectionView = TextSelectionView()
    private let lastFragmentViews = NSMutableSet()
    private var heightConstraint: NSLayoutConstraint? = nil
    
    var fragmentViewMap: NSMapTable<NSTextLayoutFragment, TextLayoutFragmentView>
    
    override init(frame: CGRect) {
        fatalError("Do not use this initializer")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Do not use this initializer")
    }
    
    init(viewModel: DocumentViewModel) {
        self.viewModel = viewModel
        fragmentViewMap = .weakToWeakObjects()
        super.init(frame: .zero)
        
        menu = NSMenu()
        menu?.addItem(NSMenuItem(title: NSLocalizedString("Cut", comment: "Menu item title"), action: #selector(cut(_:)), keyEquivalent: ""))
        menu?.addItem(NSMenuItem(title: NSLocalizedString("Copy", comment: "Menu item title"), action: #selector(copy(_:)), keyEquivalent: ""))
        menu?.addItem(NSMenuItem(title: NSLocalizedString("Paste", comment: "Menu item title"), action: #selector(paste(_:)), keyEquivalent: ""))
        
        viewModel.viewModelDelegate = self

        addSubview(selectionView)
        selectionView.autoresizingMask = [.width, .height]
        fragmentViewMap = NSMapTable.weakToWeakObjects()
        translatesAutoresizingMaskIntoConstraints = false
        
        configureWritingTools()
    }
    
    // MARK: Writing Tools
    var writingToolsContext: NSWritingToolsCoordinator.Context?
    var writingToolsRange: NSRange?
    var overlayRectViews = [NSWritingToolsCoordinator.TextAnimation: [NSView]]()
    
    func configureWritingTools() {
        guard NSWritingToolsCoordinator.isWritingToolsAvailable else { return }
        
        let coordinator = NSWritingToolsCoordinator(delegate: self)
        self.writingToolsCoordinator = coordinator
    }
    
    override var isFlipped: Bool { return true }
    
    override func layout() {
        super.layout()
        updateContentSizeIfNeeded()
        adjustViewportOffsetIfNeeded()
        textLayoutManager?.textViewportLayoutController.layoutViewport()
    }

    override var acceptsFirstResponder: Bool { return true }
    
    override class var isCompatibleWithResponsiveScrolling: Bool { return true }
    
    // MARK: - NSTextViewportLayoutControllerDelegate
    
    func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        let overdrawRect = preparedContentRect
        let visibleRect = self.visibleRect
        var minY: CGFloat = 0
        var maxY: CGFloat = 0
        if overdrawRect.intersects(visibleRect) {
            // Use preparedContentRect for vertical overdraw and ensure visibleRect is included at the minimum,
            // the width is always bounds width for proper line wrapping.
            minY = min(overdrawRect.minY, max(visibleRect.minY, 0))
            maxY = max(overdrawRect.maxY, visibleRect.maxY)
        } else {
            // Use visibleRect directly if preparedContentRect doesn't intersect.
            // This might happen if overdraw hasn't caught up with scrolling, such as before the first layout.
            minY = visibleRect.minY
            maxY = visibleRect.maxY
        }
        return CGRect(x: bounds.minX, y: minY, width: bounds.width, height: maxY - minY)
    }
    
    func textViewportLayoutControllerWillLayout(_ controller: NSTextViewportLayoutController) {
        for view in self.subviews where view is TextLayoutFragmentView {
            lastFragmentViews.add(view)
        }
    }
    
    func textViewportLayoutControllerDidLayout(_ controller: NSTextViewportLayoutController) {
        for obj in lastFragmentViews {
            if let textView = obj as? TextLayoutFragmentView {
                textView.removeFromSuperview()
                fragmentViewMap.removeObject(forKey: textView.layoutFragment)
            }
        }
        lastFragmentViews.removeAllObjects()

        updateSelectionHighlights()
    }
    
    private func findOrCreateView(_ textLayoutFragment: NSTextLayoutFragment) -> (TextLayoutFragmentView, Bool) {
        if let view = fragmentViewMap.object(forKey: textLayoutFragment) {
            return (view, false)
        } else {
            let view = TextLayoutFragmentView(element: textLayoutFragment)
            fragmentViewMap.setObject(view, forKey: textLayoutFragment)
            return (view, true)
        }
    }
    
    func textViewportLayoutController(_ controller: NSTextViewportLayoutController,
                                      configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        let renderingSurfaceBounds = textLayoutFragment.renderingSurfaceBounds
        let (textView, viewIsNew) = findOrCreateView(textLayoutFragment)
        
        if !renderingSurfaceBounds.isEmpty {
            if !viewIsNew {
                lastFragmentViews.remove(textView)
            }
        } else {
            fragmentViewMap.removeObject(forKey: textLayoutFragment)
        }

        if textView.superview != self {
            self.addSubview(textView)
        }
        textView.needsDisplay = true
    }
    
    private func updateSelectionHighlights() {
        if selectionView.superview != self {
            // If the selection view is somehow removed from the DocumentView,
            // add the selection view back and make sure it's at the bottom of the stack.
            print("Selection view has been removed from the DocumentView, adding back.")
            let currentSubViews = self.subviews
            self.subviews.removeAll()
            self.addSubview(selectionView)
            for view in currentSubViews {
                self.addSubview(view)
            }
        }
        if textLayoutManager!.textSelections.isEmpty { return }
        selectionView.clearSelectionsAndCaret()
        for textSelection in textLayoutManager!.textSelections {
            for textRange in textSelection.textRanges {
                textLayoutManager!.enumerateTextSegments(
                    in: textRange, type: .highlight,
                    options: []) {(textSegmentRange, textSegmentFrame, baselinePosition, textContainer) in
                    if textSegmentFrame.size.width > 0 {
                        selectionView.drawSelection(frame: textSegmentFrame)
                    } else {
                        selectionView.drawCaret(frame: textSegmentFrame)
                    }
                    return true // keep going
                }
            }
        }
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        needsLayout = true
    }

    private var scrollView: NSScrollView? {
        guard let result = enclosingScrollView else { return nil }
        if result.documentView == self {
            return result
        } else {
            return nil
        }
    }
    
    func updateContentSizeIfNeeded() {
        let currentHeight = bounds.height
        var height: CGFloat = 0
        textLayoutManager!.enumerateTextLayoutFragments(from: textLayoutManager!.documentRange.endLocation,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            height = layoutFragment.layoutFragmentFrame.maxY
            return false // stop
        }
        height = max(height, enclosingScrollView?.contentSize.height ?? 0)
        if abs(currentHeight - height) > 1e-10 {
            if heightConstraint == nil {
                heightConstraint = self.heightAnchor.constraint(equalToConstant: height)
                heightConstraint?.isActive = true
            } else {
                heightConstraint?.constant = height
            }
        }
    }
    
    private func adjustViewportOffsetIfNeeded() {
        guard let scrollView else {
            return
        }
        
        let viewportLayoutController = viewModel.textLayoutManager.textViewportLayoutController
        let contentOffset = scrollView.contentView.bounds.minY
        if contentOffset < scrollView.contentView.bounds.height &&
            viewportLayoutController.viewportRange?.location.compare(textLayoutManager!.documentRange.location) == .orderedDescending {
            // Nearing top, check the view port to determine whether to adjust and make room above.
            adjustViewportOffset()
        } else if viewportLayoutController.viewportRange?.location.compare(textLayoutManager!.documentRange.location) == .orderedSame {
            // At the top, check the view port to determine whether to adjust and reduce space above.
            adjustViewportOffset()
        }
    }
    
    private func adjustViewportOffset() {
        let viewportLayoutController = textLayoutManager!.textViewportLayoutController
        var layoutYPoint: CGFloat = 0
        textLayoutManager!.enumerateTextLayoutFragments(from: viewportLayoutController.viewportRange!.location,
                                                        options: [.reverse, .ensuresLayout]) { layoutFragment in
            layoutYPoint = layoutFragment.layoutFragmentFrame.origin.y
            return true
        }
        if layoutYPoint != 0 {
            let adjustmentDelta = bounds.minY - layoutYPoint
            viewportLayoutController.adjustViewport(byVerticalOffset: adjustmentDelta)
            scroll(CGPoint(x: scrollView!.contentView.bounds.minX, y: scrollView!.contentView.bounds.minY + adjustmentDelta))
        }
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        let clipView = scrollView?.contentView
        if clipView != nil {
            NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: clipView)
        }

        super.viewWillMove(toSuperview: newSuperview)
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()

        let clipView = scrollView?.contentView
        if clipView != nil {
            boundsDidChangeObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                                                                             object: clipView,
                                                                             queue: nil) { [weak self] notification in
                Task { @MainActor in
                    self?.needsLayout = true
                }
            }
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateTextContainerSize()
    }
    
    private func updateTextContainerSize() {
        let textContainer = textLayoutManager!.textContainer
        if textContainer != nil && textContainer!.size.width != bounds.width {
            textContainer!.size = NSSize(width: bounds.size.width, height: 0)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        inputContext?.activate()
        return true
    }
    
    // Center the selection in the view.
    override func centerSelectionInVisibleArea(_ sender: Any?) {
        if !textLayoutManager!.textSelections.isEmpty {
            let viewportOffset =
            textLayoutManager!.textViewportLayoutController.relocateViewport(to: textLayoutManager!.textSelections[0].textRanges[0].location)
            scroll(CGPoint(x: 0, y: viewportOffset))
        }
    }
}

extension DocumentView: @preconcurrency ViewModelDelegate {
    func textDidChange() {
        needsLayout = true
    }
    
    func selectionDidChange() {
        updateSelectionHighlights()
        // Notify the toolbar about the selection change so it can update the Bold button.
        self.window?.toolbar?.validateVisibleItems()
    }
}
