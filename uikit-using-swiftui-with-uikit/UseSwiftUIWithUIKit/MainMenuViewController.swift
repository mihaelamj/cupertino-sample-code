/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main menu for selecting different examples.
*/

import UIKit
import SwiftUI

private struct MenuItem {
    var title: String
    var subtitle: String
    var viewControllerProvider: () -> UIViewController
    
    static let allExamples = [
        MenuItem(title: "SwiftUI View Controllers",
                 subtitle: "Using UIHostingController",
                 viewControllerProvider: { HostingControllerViewController() }),
        MenuItem(title: "SwiftUI in Cells",
                 subtitle: "Using UIHostingConfiguration",
                 viewControllerProvider: { HostingConfigurationViewController() }),
        MenuItem(title: "Data Flow with SwiftUI Cells",
                 subtitle: "Using ObservableObject",
                 viewControllerProvider: { MedicalConditionsViewController() })
    ]
}

class MainMenuViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    private var collectionView: UICollectionView!
    
    override func loadView() {
        setUpCollectionView()
        view = collectionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Examples"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        deselectSelectedItem(animated)
    }
    
    private func deselectSelectedItem(_ animated: Bool) {
        guard let indexPath = collectionView.indexPathsForSelectedItems?.first else { return }
        
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.collectionView.deselectItem(at: indexPath, animated: true)
            }, completion: { context in
                if context.isCancelled {
                    self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            })
        } else {
            collectionView.deselectItem(at: indexPath, animated: animated)
        }
    }
    
    private func setUpCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let listConfig = UICollectionLayoutListConfiguration(appearance: .plain)
            let layoutSection = NSCollectionLayoutSection.list(using: listConfig, layoutEnvironment: layoutEnvironment)
            return layoutSection
        }
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private var cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, MenuItem> = {
        .init { cell, indexPath, item in
            cell.accessories = [.disclosureIndicator()]
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.secondaryText = item.subtitle
            content.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = content
        }
    }()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        MenuItem.allExamples.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = MenuItem.allExamples[indexPath.item]
        return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
    }
    
    func collectionView(_ collectionView: UICollectionView, performPrimaryActionForItemAt indexPath: IndexPath) {
        let item = MenuItem.allExamples[indexPath.item]
        let viewController = item.viewControllerProvider()
        navigationController?.pushViewController(viewController, animated: true)
    }
    
}

