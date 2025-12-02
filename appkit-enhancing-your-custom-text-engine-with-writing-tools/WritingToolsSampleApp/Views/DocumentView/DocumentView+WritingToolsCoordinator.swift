/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of a Writing Tools coordinator for the intelligent text document view.
*/

import Cocoa

extension DocumentView: @preconcurrency NSWritingToolsCoordinator.Delegate {
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        requestsContextsFor scope: NSWritingToolsCoordinator.ContextScope,
        completion: @escaping ([NSWritingToolsCoordinator.Context]) -> Void) {
            let selectedText = viewModel.firstSelectedAttributedString
            let selectedRange = viewModel.firstSelectedRange ?? NSRange()

            if selectedRange.length == 0 {
                // When no text is selected, use the whole document with cursor location.
                writingToolsContext = NSWritingToolsCoordinator.Context(
                    attributedString: viewModel.allText,
                    range: selectedRange)
                writingToolsRange = NSRange(location: 0, length: viewModel.allText.length)
            } else {
                // When there is selected text, then use it.
                writingToolsContext = NSWritingToolsCoordinator.Context(
                    attributedString: selectedText,
                    range: NSRange(location: 0, length: selectedText.length))
                writingToolsRange = selectedRange
            }

            completion([writingToolsContext!])
    }

    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        replace range: NSRange, in context: NSWritingToolsCoordinator.Context,
        proposedText replacementText: NSAttributedString,
        reason: NSWritingToolsCoordinator.TextReplacementReason,
        animationParameters: NSWritingToolsCoordinator.AnimationParameters?,
        completion: @escaping (NSAttributedString?) -> Void) {
            let adjustedRange = adjustRange(range, forContext: context)
            viewModel.replaceText(inRange: adjustedRange, with: replacementText)

            let newLength = writingToolsRange!.length - range.length + replacementText.length
            let newRange = NSRange(location: writingToolsRange!.location, length: newLength)
            writingToolsRange! = newRange

            completion(replacementText)
    }
    
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        select ranges: [NSValue], in context: NSWritingToolsCoordinator.Context,
        completion: @escaping () -> Void) {
            defer {
                completion()
            }
            
            guard let range = ranges.first as? NSRange else {
                print("Asked to select range with no range")
                return
            }
            
            let adjustedRange = adjustRange(range, forContext: context)
            guard adjustedRange.location != NSNotFound else {
                print("Asked to select a range with NSNotFound")
                return
            }
            
            viewModel.selectDocumentText(inNSRange: adjustedRange)
    }
    
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        requestsBoundingBezierPathsFor range: NSRange,
        in context: NSWritingToolsCoordinator.Context,
        completion: @escaping ([NSBezierPath]) -> Void) {
            guard let selectionRects = selectionRects(forRange: range) else {
                print("Could not return bounding bezier paths")
                completion([])
                return
            }
            
            var paths = [NSBezierPath]()
            for rect in selectionRects {
                paths.append(NSBezierPath(rect: rect))
            }
            completion(paths)
    }
    
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        requestsUnderlinePathsFor range: NSRange,
        in context: NSWritingToolsCoordinator.Context,
        completion: @escaping ([NSBezierPath]) -> Void) {
            guard let selectionRects = selectionRects(forRange: range) else {
                print("Could not return underline paths")
                completion([])
                return
            }
            
            var paths = [NSBezierPath]()
            for rect in selectionRects {
                // Squish the rect down so it has the standard 2 point height
                let underlineHeight: CGFloat = 2
                let newRect = NSRect(
                    x: rect.origin.x,
                    y: rect.origin.y + rect.height - underlineHeight,
                    width: rect.width,
                    height: underlineHeight)
                paths.append(NSBezierPath(rect: newRect))
            }
            completion(paths)
    }
    
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        prepareFor textAnimation: NSWritingToolsCoordinator.TextAnimation,
        for range: NSRange,
        in context: NSWritingToolsCoordinator.Context,
        completion: @escaping () -> Void) {
            defer {
                completion()
            }
            
            print("prepareFor: \(textAnimation) for range: \(range) in context: \(context.identifier)")
            
            // Put overlay views over the areas of text that are being animated, so they are hidden.
            // To do this, make new UIView objects for each of the rectangles from TextKit.
            guard let selectionRects = selectionRects(forRange: range) else {
                print("Failed to get selection rects for this animation")
                return
            }

            // Create the new views to overlay the text and then add them to the main view.
            var newViews = [NSView]()
            for rect in selectionRects {
                let newView = NSView(frame: rect)
                newView.wantsLayer = true
                newView.layer?.backgroundColor = NSColor.selectedTextBackgroundColor.cgColor
                newView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(newView)
                newViews.append(newView)
            }
            overlayRectViews[textAnimation] = newViews
    }
    
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        requestsPreviewFor textAnimation: NSWritingToolsCoordinator.TextAnimation,
        of range: NSRange,
        in context: NSWritingToolsCoordinator.Context,
        completion: @escaping ([NSTextPreview]?) -> Void) {
            // Get the adjusted range in the document from the given context.
            guard let selectionRects = selectionRects(forRange: range) else {
                print("Failed to get selection rects for this preview")
                completion(nil)
                return
            }
            
            // Get the selection union in order to render the text in that area.
            let unionRect = viewModel.unionRect(for: selectionRects.map { $0 })
            guard unionRect != CGRect.zero else {
                print("We have a zero rect")
                completion(nil)
                return
            }
            
            guard let image = renderTextInRect(unionRect) else {
                completion(nil)
                return
            }
            
            completion([NSTextPreview(snapshotImage: image, presentationFrame: unionRect)])
    }
    
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        requestsPreviewFor rect: NSRect,
        in context: NSWritingToolsCoordinator.Context,
        completion: @escaping (NSTextPreview?) -> Void) {
            guard let image = renderTextInRect(rect) else {
                print("Could not create preview, returning nil")
                completion(nil)
                return
            }

            let preview = NSTextPreview(snapshotImage: image, presentationFrame: rect)
            completion(preview)
            return
    }
    
    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        finish textAnimation: NSWritingToolsCoordinator.TextAnimation,
        for range: NSRange,
        in context: NSWritingToolsCoordinator.Context,
        completion: @escaping () -> Void) {
            defer {
                completion()
            }
                        
            guard let existingViews = overlayRectViews[textAnimation] else {
                return
            }
            
            for existingView in existingViews {
                existingView.removeFromSuperview()
            }
            overlayRectViews[textAnimation] = nil
    }

    func writingToolsCoordinator(
        _ writingToolsCoordinator: NSWritingToolsCoordinator,
        willChangeTo newState: NSWritingToolsCoordinator.State,
        completion: @escaping () -> Void) {
            switch newState {
            case .inactive:
                // Clean up the local states when session is over.
                writingToolsContext = nil
                writingToolsRange = nil

                // Tear down any special views.
                for (_, views) in self.overlayRectViews {
                    for view in views {
                        view.removeFromSuperview()
                    }
                }
                self.overlayRectViews.removeAll()
                self.textDidChange()
                completion()
            case .noninteractive, .interactiveResting, .interactiveStreaming:
                fallthrough
            @unknown default:
                completion()
            }
    }
}

extension DocumentView {
    func adjustRange(
        _ range: NSRange,
        forContext context: NSWritingToolsCoordinator.Context) -> NSRange {
        
        let originalLocation = writingToolsRange!.location
        let adjustedRange = NSRange(location: originalLocation + range.location, length: range.length)
        return adjustedRange
    }
    
    func selectionRects(forRange range: NSRange) -> [NSRect]? {
        let adjustedRange = NSRange(location: writingToolsRange!.location + range.location, length: range.length)
        let selectionRects = viewModel.selectionRects(for: adjustedRange)
        return selectionRects
    }
    
    func renderTextInRect(_ rect: CGRect) -> CGImage? {
        let scaleFactor = self.window!.backingScaleFactor
        let bitsPerComponent = 8
        let numberOfComponents = 4
        let pixelWidth = Int(rect.size.width * scaleFactor)
        let pixelHeight = Int(rect.size.height * scaleFactor)
        let bytesPerRow = pixelWidth * numberOfComponents
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil, width: pixelWidth, height: pixelHeight,
            bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow,
            space: colorSpace, bitmapInfo: bitmapInfo)
        else {
            print("Could not create context")
            return nil
        }
        
        context.scaleBy(x: scaleFactor, y: -scaleFactor)
        context.translateBy(x: 0, y: -rect.size.height)
        // Translate coordinates for origin.
        context.translateBy(x: -rect.origin.x, y: -rect.origin.y)
        
        for object in fragmentViewMap.objectEnumerator() ?? NSEnumerator() {
            let fragmentView = object as? TextLayoutFragmentView
            if fragmentView?.frame.intersects(rect) != nil {
                fragmentView?.draw(context)
            }
        }
        
        guard let image = context.makeImage() else {
            print("Could not create image")
            return nil
        }
        
        return image
    }
}
