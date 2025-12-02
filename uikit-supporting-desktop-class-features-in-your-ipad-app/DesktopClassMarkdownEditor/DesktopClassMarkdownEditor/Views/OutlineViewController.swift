/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that manages the document outline view.
*/

import UIKit

protocol OutlineViewControllerDelegate: AnyObject {
    func outline(_ outlineView: OutlineViewController, didChoose element: OutlineElement)
    func outline(_ outlineView: OutlineViewController, didSwapTagsFor elements: [OutlineElement], withTag: MarkdownTag)
    func outline(_ outlineView: OutlineViewController, didDuplicate elements: [OutlineElement])
    func outline(_ outlineView: OutlineViewController, didDelete elements: [OutlineElement])
}

class OutlineViewController: UIViewController, UICollectionViewDelegate {

    weak var delegate: OutlineViewControllerDelegate?

    var outlineElements: [OutlineElement] = [] {
        didSet {
            guard self.isViewLoaded else { return }
            updateSnapshot()
        }
    }

    private var collectionView: UICollectionView {
        self.view as! UICollectionView
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, OutlineElement>!

    override func loadView() {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    }

    /// - Tag: OutlineViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Table of Contents"

        collectionView.delegate = self

        // Enable multiple selection.
        collectionView.allowsMultipleSelection = true

        // Enable keyboard focus.
        collectionView.allowsFocus = true

        // Allow keyboard focus to drive selection.
        collectionView.selectionFollowsFocus = true
        
        configureDataSource()
    }
    
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineElement> { cell, indexPath, item in
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = item.formattedText
            contentConfiguration.textProperties.font = item.font
            contentConfiguration.textProperties.numberOfLines = item.maxLineCount
            contentConfiguration.textProperties.lineBreakMode = .byTruncatingTail
            contentConfiguration.image = item.image
            cell.contentConfiguration = contentConfiguration
        }

        dataSource = UICollectionViewDiffableDataSource<Section, OutlineElement>(
            collectionView: collectionView) { collectionView, indexPath, element in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: element)
            cell.indentationLevel = element.indendationLevel
            cell.indentationWidth = 5
            return cell
        }

        updateSnapshot()
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, OutlineElement>()
        snapshot.appendSections([.outline])
        snapshot.appendItems(outlineElements)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// The system calls this method only when the user chooses an item. The system doesn't call this
    /// method if the user is performing a multiple selection to invoke a context menu.
    /// - Tag: PrimaryAction
    func collectionView(_ collectionView: UICollectionView, performPrimaryActionForItemAt indexPath: IndexPath) {
        // Get the element at the `indexPath`.
        if let element = dataSource.itemIdentifier(for: indexPath) {
            delegate?.outline(self, didChoose: element)
        }

        // Wait a short amount of time before deselecting the cell for visual clarity.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    // MARK: Context Menu
    /// The system calls this method after a user invokes a context menu from the collection view.
    /// The `indexPaths` array can contain zero or more items.
    /// - An empty array indicates that a user invokes the menu in an empty space. The returned menu
    /// includes actions that don't act on any particular item in the collection view.
    /// - An array with one item indicates that a user invokes the menu on a single item. The returned
    /// menu acts on that one item.
    /// - An array with two or more items indicates that a user invokes the menu within a multiple
    /// selection. The returned menu acts on all selected items.
    /// - Tag: ContextMenus
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint) -> UIContextMenuConfiguration? {
        // The outline view doesn't support an empty-space menu, so return nil.
        if indexPaths.isEmpty { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            var hideTitle: String
            var deleteTitle: String
            
            if indexPaths.count > 1 {
                // Action titles for a multiple-item menu.
                hideTitle = "Hide Selected"
                deleteTitle = "Delete Selected"
            } else {
                // Action titles for a single-item menu.
                hideTitle = "Hide"
                deleteTitle = "Delete"
            }
            
            let outlineElements = indexPaths.compactMap {
                self.dataSource.itemIdentifier(for: $0)
            }
            
            // Generate tag specific actions for the selected elements.
            let tagSpecificActions = self.tagSpecificActions(for: outlineElements)
            
            return UIMenu(children: [
                UIMenu(options: .displayInline, children: tagSpecificActions),
                UIAction(title: "Duplicate", image: UIImage(systemName: "plus.rectangle.on.rectangle")) { [unowned self] _ in
                    duplicate(outlineElements)
                },
                UIAction(title: hideTitle, image: UIImage(systemName: "eye.slash")) { [unowned self] _ in
                    set(tag: .comment, for: outlineElements)
                },
                UIMenu(options: .displayInline, children: [
                    UIAction(title: deleteTitle, image: UIImage(systemName: "trash"), attributes: .destructive) { [unowned self] _ in
                        deleteElements(outlineElements)
                    }
                ])
            ])
        }
    }
    
    /// Returns tag-specific actions if all items in `elements` have the same tag.
    private func tagSpecificActions(for elements: [OutlineElement]) -> [UIMenuElement] {
                
        var actions = [UIMenuElement]()

        // Check if all elements in the array have the same tag.
        if let firstElement = elements.first, elements.allSatisfy({ $0.representation == firstElement.representation }) {
            switch firstElement.representation {
            case .heading(let level):
                // For headings, generate a menu that allows changing the
                // heading level.
                let headings = (1...6).map { levelCase in
                    UIAction(title: "Heading \(levelCase)", state: (levelCase == level ? .on : .off)) { [unowned self] _ in
                        set(tag: .heading(levelCase), for: elements)
                    }
                }
                actions.append(UIMenu(title: "Heading", subtitle: "Heading \(level)", children: headings))
                
            case .codeBlock(let language):
                // For code blocks, generate a menu that allows changing the
                // language.
                let languages = MarkdownTag.Language.allCases.map { languageCase in
                    UIAction(title: languageCase.rawValue,
                             image: languageCase.image,
                             state: (languageCase == language ? .on : .off)) { [unowned self] _ in
                        set(tag: .codeBlock(languageCase), for: elements)
                    }
                }
                actions.append(UIMenu(title: "Language", subtitle: language.rawValue, children: languages))
            }
        }
        
        return actions
    }
    
    private func set(tag: MarkdownTag, for elements: [OutlineElement]) {
        delegate?.outline(self, didSwapTagsFor: elements, withTag: tag)
    }
    
    private func duplicate(_ elements: [OutlineElement]) {
        delegate?.outline(self, didDuplicate: elements)
    }
    
    private func deleteElements(_ elements: [OutlineElement]) {
        delegate?.outline(self, didDelete: elements)
    }
}

private extension OutlineViewController {
    enum Section: Hashable {
        case outline
    }
}

private extension OutlineElement {
    var formattedText: String {
        switch representation {
        case .codeBlock:
            // For code, remove whitespace lines.
            return text.components(separatedBy: .newlines)
                .filter { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }
                .joined(separator: "\n")
        default:
            return text
        }
    }

    var image: UIImage? {
        switch representation {
        case .codeBlock(let language):
            return language.image
        default:
            return nil
        }
    }

    var font: UIFont {
        switch representation {
        case .heading(let headingLevel):
            return .systemFont(ofSize: UIFont.labelFontSize, weight: .heading(level: headingLevel))
        case .codeBlock:
            return .monospacedSystemFont(ofSize: UIFont.smallSystemFontSize, weight: .regular)
        }
    }

    var textColor: UIColor {
        switch representation {
        case .codeBlock(_): return .secondaryLabel
        default: return .label
        }
    }

    var maxLineCount: Int {
        switch representation {
        case .heading: return 0
        case .codeBlock: return 2
        }
    }
}

private extension UIFont.Weight {
    static func heading(level: Int) -> UIFont.Weight {
        switch level {
        case 0: return .heavy
        case 1: return .bold
        case 2: return .semibold
        case 3: return .medium
        default:
            return .regular
        }
    }
}
