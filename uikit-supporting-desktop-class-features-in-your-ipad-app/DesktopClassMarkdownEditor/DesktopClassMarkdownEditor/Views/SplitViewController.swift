/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The split view controller that manages the presentation of the document outline
 and editor views.
*/

import UIKit

class SplitViewController: UISplitViewController, EditorViewControllerDelegate, OutlineViewControllerDelegate {

    let document: MarkdownDocument
    let editorViewController: EditorViewController
    let outlineViewController: OutlineViewController

    init(document: MarkdownDocument) {
        self.document = document
        editorViewController = EditorViewController(document: document)
        outlineViewController = OutlineViewController()

        super.init(style: .doubleColumn)

        preferredDisplayMode = .secondaryOnly
        primaryBackgroundStyle = .sidebar

        editorViewController.delegate = self
        outlineViewController.delegate = self

        let outlineBarAppearance = UINavigationBarAppearance()
        outlineBarAppearance.backgroundColor = .secondarySystemBackground
        
        let outlineNavigationController = UINavigationController(rootViewController: outlineViewController)
        outlineNavigationController.navigationBar.standardAppearance = outlineBarAppearance
        setViewController(outlineNavigationController, for: .primary)

        let editorBarAppearance = UINavigationBarAppearance()
        editorBarAppearance.backgroundColor = UIColor {
            if $0.userInterfaceStyle == .light {
                return .white
            } else {
                return UIColor(named: "EditorBackgroundColor")!
            }
        }
        
        editorViewController.navigationItem.standardAppearance = editorBarAppearance
        editorViewController.navigationItem.scrollEdgeAppearance = editorBarAppearance

        let editorNavigationController = UINavigationController(rootViewController: editorViewController)
        setViewController(editorNavigationController, for: .secondary)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: EditorViewControllerDelegate
    
    func editor(_ editorViewController: EditorViewController, didParse document: ParsedDocument) {
        outlineViewController.outlineElements = document.outline
    }

    // MARK: OutlineViewControllerDelegate

    func outline(_ outlineView: OutlineViewController, didChoose element: OutlineElement) {
        // If the app is in compact width, this will push the editor, otherwise it will have no effect.
        show(.secondary)
        editorViewController.scroll(to: element)
    }
    
    func outline(_ outlineView: OutlineViewController, didSwapTagsFor elements: [OutlineElement], withTag tag: MarkdownTag) {
        document.swapTags(for: elements, with: tag)
    }
    
    func outline(_ outlineView: OutlineViewController, didDuplicate elements: [OutlineElement]) {
        document.duplicate(elements)
    }
    
    func outline(_ outlineView: OutlineViewController, didDelete elements: [OutlineElement]) {
        document.delete(elements)
    }
}

extension SplitViewController {
    enum SplitViewError: Error {
        case renamingUnavailable
        case documentFailedToOpen
    }
}
