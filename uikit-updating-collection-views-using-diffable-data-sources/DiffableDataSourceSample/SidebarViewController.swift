/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays items in the sidebar.
*/

import UIKit

/// - Tag: SidebarViewController
class SidebarViewController: UICollectionViewController {
    
    private enum SidebarSection: Int {
        case standardItems, recipeCollectionItems
        
        var headerTitle: String {
            switch self {
            case .standardItems:
                return "Library"
            case .recipeCollectionItems:
                return "Collections"
            }
        }
    }
    
    private enum StandardSidebarItem: String, CaseIterable {
        case all = "All Recipes"
        case favorites = "Favorites"
        case recents = "Recents"
    }
    
    /// - Tag: SidebarItem
    private struct SidebarItem: Hashable {
        let title: String
        let type: SidebarItemType
        
        enum SidebarItemType {
            case standard, collection, expandableHeader
        }
    }
    
    private var sidebarDataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!
    
    private var recipeSplitViewController: RecipeSplitViewController {
        self.splitViewController as! RecipeSplitViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = false
        
        configureCollectionView()
        configureDataSource()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recipeCollectionsDidChange(_:)),
            name: .recipeCollectionsDidChange,
            object: nil
        )
    }

    @objc
    private func recipeCollectionsDidChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let collections = userInfo[NotificationKeys.recipeCollections] as? [String]
        else { return }
        
        let items = collections.map { SidebarItem(title: $0, type: .collection) }
        let snapshot = createSidebarItemSnapshot(.recipeCollectionItems, items: items)
        sidebarDataSource.apply(snapshot, to: .recipeCollectionItems, animatingDifferences: true)
    }

}

extension SidebarViewController {
    
    private func configureCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.headerMode = .firstItemInSection
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
        collectionView.collectionViewLayout = layout
    }
    
}

extension SidebarViewController {
    
    private func configureDataSource() {
        let sidebarItemRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, indexPath, item) in
            
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = item.title
            
            cell.contentConfiguration = contentConfiguration
        }
        
        let expandableSectionHeaderRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, indexPath, item) in
            
            var contentConfiguration = cell.defaultContentConfiguration()
            contentConfiguration.text = item.title
            
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.outlineDisclosure()]
        }
        
        sidebarDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell in
            switch item.type {
            case .expandableHeader:
                return collectionView.dequeueConfiguredReusableCell(using: expandableSectionHeaderRegistration, for: indexPath, item: item)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: sidebarItemRegistration, for: indexPath, item: item)
            }
        }
        
        sidebarDataSource.apply(createSnapshotOfStandardItems(), to: .standardItems, animatingDifferences: false)
        sidebarDataSource.apply(createSnapshotOfRecipeCollections(), to: .recipeCollectionItems, animatingDifferences: false)
    }
    
    /// - Tag: createSnapshotOfStandardItems
    private func createSnapshotOfStandardItems() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        let items = [
            SidebarItem(title: StandardSidebarItem.all.rawValue, type: .standard),
            SidebarItem(title: StandardSidebarItem.favorites.rawValue, type: .standard),
            SidebarItem(title: StandardSidebarItem.recents.rawValue, type: .standard)
        ]
        return createSidebarItemSnapshot(.standardItems, items: items)
    }
    
    private func createSnapshotOfRecipeCollections() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        let items = recipeSplitViewController.recipeCollections.map { SidebarItem(title: $0, type: .collection) }
        return createSidebarItemSnapshot(.recipeCollectionItems, items: items)
    }
    
    private func createSidebarItemSnapshot(_ section: SidebarSection, items: [SidebarItem]) -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        let headerItem = SidebarItem(title: section.headerTitle, type: .expandableHeader)
        
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        snapshot.append([headerItem])
        snapshot.expand([headerItem])
        
        snapshot.append(items, to: headerItem)
        
        return snapshot
    }
    
}

extension SidebarViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = sidebarDataSource.itemIdentifier(for: indexPath) else { return }
                
        switch item.type {
        case .standard:
            switch StandardSidebarItem(rawValue: item.title) {
            case .favorites:
                recipeSplitViewController.selectedRecipes = SelectedRecipes(type: .favorites)
            case .recents:
                recipeSplitViewController.selectedRecipes = SelectedRecipes(type: .recents)
            default:
                recipeSplitViewController.selectedRecipes = SelectedRecipes(type: .all)
            }
        case .collection:
            recipeSplitViewController.selectedRecipes = SelectedRecipes(type: .collections, collectionName: item.title)
        default:
            recipeSplitViewController.selectedRecipes = SelectedRecipes(type: .all)
        }
    }
    
}
