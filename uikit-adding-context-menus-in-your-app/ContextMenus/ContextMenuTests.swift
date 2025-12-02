/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple outline view for the sample app's main UI
*/

import UIKit

class ContextMenuTests: UIViewController {

    enum Section {
        case main
    }

    class OutlineItem: Identifiable, Hashable {
        let title: String
        let secondaryTitle: String?
        let subitems: [OutlineItem]
        let storyboardIdentifier: String?
        let imageName: String?

        init(title: String, secondaryTitle: String?, imageName: String?, storyboardIdentifier: String? = nil, subitems: [OutlineItem] = []) {
            self.title = title
            self.secondaryTitle = secondaryTitle
            self.subitems = subitems
            self.storyboardIdentifier = storyboardIdentifier
            self.imageName = imageName
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: OutlineItem, rhs: OutlineItem) -> Bool {
            return lhs.id == rhs.id
        }

    }

    var dataSource: UICollectionViewDiffableDataSource<Section, OutlineItem>! = nil
    var outlineCollectionView: UICollectionView! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureDataSource()
        
        // Listen for when a split view controller is expanded or collapsed.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showDetailTargetDidChange(_:)),
                                               name: UIViewController.showDetailTargetDidChangeNotification,
                                               object: nil)
    }
    
    // Posted when a split view controller is expanded or collapsed.
    @objc
    func showDetailTargetDidChange(_ notification: NSNotification) {
        // Reaload the data source, the disclosure indicators need to change (push vs. present on a cell).
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems(menuItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIViewController.showDetailTargetDidChangeNotification, object: nil)
    }
    
    private lazy var menuItems: [OutlineItem] = {
        return [
            OutlineItem(title: "Views", secondaryTitle: nil, imageName: "square.on.square", subitems: [
                OutlineItem(title: "Basic", secondaryTitle: "ViewBasic.swift",
                            imageName: "line.horizontal.3", storyboardIdentifier: "ViewBasic"),
                OutlineItem(title: "Titled", secondaryTitle: "ViewTitled.swift",
                            imageName: "textformat", storyboardIdentifier: "ViewTitled"),
                OutlineItem(title: "Submenu", secondaryTitle: "ViewSubmenu.swift",
                            imageName: "chevron.down.square", storyboardIdentifier: "ViewSubmenu"),
                OutlineItem(title: "Preview", secondaryTitle: "ViewPreview.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "ViewPreview"),
                OutlineItem(title: "Preview Provider", secondaryTitle: "ViewPreviewProvider.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "ViewPreviewProvider")
            ]),
            
            OutlineItem(title: "Table Views", secondaryTitle: "", imageName: "rectangle.grid.1x2", subitems: [
                OutlineItem(title: "Basic", secondaryTitle: "TableViewBasic.swift",
                            imageName: "line.horizontal.3", storyboardIdentifier: "TableViewBasic"),
                OutlineItem(title: "Titled", secondaryTitle: "TableViewTitled.swift",
                            imageName: "textformat", storyboardIdentifier: "TableViewTitled"),
                OutlineItem(title: "Submenu", secondaryTitle: "TableViewSubmenu.swift",
                            imageName: "chevron.down.square", storyboardIdentifier: "TableViewSubmenu"),
                OutlineItem(title: "Preview", secondaryTitle: "TableViewPreview.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "TableViewPreview"),
                OutlineItem(title: "Preview Provider", secondaryTitle: "TableViewPreviewProvider.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "TableViewPreviewProvider")
            ]),
            
            OutlineItem(title: "Collection Views", secondaryTitle: "", imageName: "square.grid.2x2", subitems: [
                OutlineItem(title: "Basic", secondaryTitle: "CollectionViewBasic.swift",
                            imageName: "line.horizontal.3", storyboardIdentifier: "CollectionViewBasic"),
                OutlineItem(title: "Titled", secondaryTitle: "CollectionViewTitled.swift",
                            imageName: "textformat", storyboardIdentifier: "CollectionViewTitled"),
                OutlineItem(title: "Submenu", secondaryTitle: "CollectionViewSubmenu.swift",
                            imageName: "chevron.down.square", storyboardIdentifier: "CollectionViewSubmenu"),
                OutlineItem(title: "Preview", secondaryTitle: "CollectionViewPreview.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "CollectionViewPreview"),
                OutlineItem(title: "Preview Provider", secondaryTitle: "CollectionViewPreviewProvider.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "CollectionViewPreviewProvider")
            ]),
            
            OutlineItem(title: "Controls", secondaryTitle: "", imageName: "slider.horizontal.3", subitems: [
                OutlineItem(title: "Basic", secondaryTitle: "ControlBasic.swift",
                            imageName: "line.horizontal.3", storyboardIdentifier: "ControlBasic"),
                OutlineItem(title: "Preview", secondaryTitle: "ControlPreview.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "ControlPreview"),
                OutlineItem(title: "Preview Provider", secondaryTitle: "ControlPreviewProvider.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "ControlPreviewProvider")
            ]),
            
            OutlineItem(title: "Web Views", secondaryTitle: "", imageName: "globe", subitems: [
                OutlineItem(title: "Basic", secondaryTitle: "WebViewBasic.swift",
                            imageName: "line.horizontal.3", storyboardIdentifier: "WebViewBasic"),
                OutlineItem(title: "Preview Provider", secondaryTitle: "WebViewPreviewProvider.swift",
                            imageName: "photo.on.rectangle", storyboardIdentifier: "WebViewPreviewProvider")
            ])
        ]
    }()

}

// MARK: - UICollectionViewDiffableDataSource

extension ContextMenuTests {

    private func configureCollectionView() {
        let collectionView =
            UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemBackground
        self.outlineCollectionView = collectionView
        collectionView.delegate = self
    }

    private func configureDataSource() {

        let containerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineItem> { (cell, indexPath, menuItem) in

            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = menuItem.title
            if let imageName = menuItem.imageName {
                contentConfiguration.image = UIImage(systemName: imageName)
            }
            
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
            cell.contentConfiguration = contentConfiguration
            
            let disclosureOptions = UICellAccessory.OutlineDisclosureOptions(style: .header)
            cell.accessories = [.outlineDisclosure(options: disclosureOptions)]
            
            let background = UIBackgroundConfiguration.clear()
            cell.backgroundConfiguration = background
        }
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, OutlineItem> { cell, indexPath, menuItem in
            var content = UIListContentConfiguration.cell()
            content.text = menuItem.title
            content.secondaryText = menuItem.secondaryTitle
            if let imageName = menuItem.imageName {
                content.image = UIImage(systemName: imageName)
            }
            cell.contentConfiguration = content
            
            let background = UIBackgroundConfiguration.clear()
            cell.backgroundConfiguration = background
            
            cell.accessories = self.splitViewWantsToShowDetail() ? [] : [.disclosureIndicator()]
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, OutlineItem>(collectionView: outlineCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: OutlineItem) -> UICollectionViewCell? in
            // Return the cell.
            if item.subitems.isEmpty {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: containerCellRegistration, for: indexPath, item: item)
            }
        }

        // Load initial data.
        let snapshot = initialSnapshot()
        self.dataSource.apply(snapshot, to: .main, animatingDifferences: false)
    }

    private func generateLayout() -> UICollectionViewLayout {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        return layout
    }

    private func initialSnapshot() -> NSDiffableDataSourceSectionSnapshot<OutlineItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<OutlineItem>()

        func addItems(_ menuItems: [OutlineItem], to parent: OutlineItem?) {
            snapshot.append(menuItems, to: parent)
            for menuItem in menuItems where !menuItem.subitems.isEmpty {
                addItems(menuItem.subitems, to: menuItem)
            }
        }
        
        addItems(menuItems, to: nil)
        return snapshot
    }

}

// MARK: - UICollectionViewDelegate

extension ContextMenuTests: UICollectionViewDelegate {
    
    private func splitViewWantsToShowDetail() -> Bool {
        return splitViewController?.traitCollection.horizontalSizeClass == .regular
    }
    
    private func pushOrPresentViewController(viewController: UIViewController) {
        if splitViewWantsToShowDetail() {
            let navVC = UINavigationController(rootViewController: viewController)
            splitViewController?.showDetailViewController(navVC, sender: navVC) // Replace the detail view controller.
        } else {
            navigationController?.pushViewController(viewController, animated: true) // Just push instead of replace.
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let menuItem = self.dataSource.itemIdentifier(for: indexPath) else { return }
        
        collectionView.deselectItem(at: indexPath, animated: true)
    
        if let identifier = menuItem.storyboardIdentifier {
            if let exampleViewController = self.storyboard?.instantiateViewController(identifier: identifier) {
                exampleViewController.title = menuItem.title
                pushOrPresentViewController(viewController: exampleViewController)
            }
        }
    }
    
}
